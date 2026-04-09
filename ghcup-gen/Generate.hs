{-# LANGUAGE CPP              #-}
{-# LANGUAGE DataKinds        #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes      #-}
{-# LANGUAGE TemplateHaskell  #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ViewPatterns     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

module Generate where

import           GHCup
import           GHCup.Download
import           GHCup.Requirements
import           GHCup.Errors
import           GHCup.Types
import           GHCup.Types.Optics
import           GHCup.Utils
import           GHCup.Prelude
import           GHCup.Prelude.Version.QQ


import           Codec.Archive
import           Control.DeepSeq
import           Control.Exception              ( evaluate )
import           Control.Exception.Safe      hiding ( handle )
import           Control.Monad
import           Control.Monad.State.Lazy
import           Control.Monad.IO.Class
import           Control.Monad.Reader.Class
import           Control.Monad.Trans.Resource   ( runResourceT
                                                , MonadUnliftIO
                                                )
import qualified Data.Aeson                   as Aeson
import qualified Data.Aeson.Encode.Pretty     as Aeson
import           Data.ByteString                ( ByteString )
import           Data.Either
import           Data.Functor
import           Data.Maybe
import           Data.List.NonEmpty (NonEmpty((:|)))
import           Data.List
import           Data.Map.Strict                ( Map )
import           Data.Versions
import           Data.Variant.Excepts
import           System.Exit
import           System.FilePath
import           System.IO
import           Text.Regex.Posix
import           GHCup.Prelude.String.QQ

import qualified Data.ByteString.Lazy          as BSL
import qualified Data.ByteString.UTF8 as UTF8
import qualified Data.Map.Strict               as M
import qualified Data.Text                     as T
import qualified Data.Yaml.Pretty              as YAML
import qualified Text.Megaparsec               as MP

import           Data.Bifoldable                (bifoldMap)
import           Data.Foldable                  (traverse_)
import           Data.Text                      (Text)

import           Text.PrettyPrint.HughesPJClass (pPrint, prettyShow)


data Format = FormatJSON
            | FormatYAML

data Output
  = FileOutput FilePath -- optsparse-applicative doesn't handle ByteString correctly anyway
  | StdOut

type HlsGhcVersions = Map Version (Map Architecture (Map Platform Version))

type HlsGhcInstallSpec = Map Version (Map Architecture (Map Platform [Version]))

generateHLSGhcInstallInfo ::
  ( MonadFail m
  , MonadMask m
  , Monad m
  , MonadThrow m
  , MonadIO m
  , MonadUnliftIO m
  )
  => Output
  -> ByteString
  -> m ExitCode
generateHLSGhcInstallInfo output data' = do
  handle <- case output of
              StdOut -> pure stdout
              FileOutput fp -> liftIO $ openFile fp WriteMode
  a <- either fail pure $ Aeson.eitherDecodeStrict @HlsGhcInstallSpec data'
  r <- forM (M.toList a) $ \(hlsVer, mArch) -> flip evalStateT [] $
    forM (M.toList mArch) $ \(arch, mPlat) ->
      forM (M.toList mPlat) $ \(plat, ghcVers) -> do
        let exeExt = if plat == Windows then ".exe" else ""
        let exeGhcRules = ghcVers <&> \ghcVer -> InstallFileRule ("haskell-language-server-" <> T.unpack (prettyVer ghcVer) <.> exeExt) Nothing
        let symlinkGhcRules = ghcVers <&> \ghcVer ->
               SymlinkSpec {
                 _slTarget = "haskell-language-server-" <> T.unpack (prettyVer ghcVer) <.> exeExt
               , _slLinkName = "haskell-language-server-" <> T.unpack (prettyVer ghcVer) <> "~${PKGVER}" <.> exeExt
               , _slPVPMajorLinks = False
               , _slSetName = Just $ "haskell-language-server-" <> T.unpack (prettyVer ghcVer) <.> exeExt
               }

        installInfo <- if hlsVer >= [vver|1.7.0.0|]
        then do
          pure $ InstallBindistMake $
                InstallMakeInfo {
                  _imiConfigArgs = []
                , _imiConfigEnv  = []
                , _imiConfigFile = Nothing
                , _imiMakeArgs   = ["DESTDIR=${TMPDIR}", "PREFIX=${PREFIX}", "install"]
                , _imiMakeEnv    = []
                , _imiPreserveMtimes = False
                , _imiExeSymLinked = SymlinkSpec {
                                       _slTarget = "haskell-language-server-wrapper" <.> exeExt
                                     , _slLinkName = "haskell-language-server-wrapper-${PKGVER}" <.> exeExt
                                     , _slPVPMajorLinks = False
                                     , _slSetName = Just $ "haskell-language-server-wrapper" <.> exeExt
                                     } : symlinkGhcRules
                }
        else do
          pure $ InstallBindistFiles $
                InstallExecutablesInfo
                (InstallFileRule ("haskell-language-server-wrapper" <.> exeExt) Nothing :| exeGhcRules)
                []
                ((SymlinkSpec {
                  _slTarget = "haskell-language-server-wrapper" <.> exeExt
                , _slLinkName = "haskell-language-server-wrapper-${PKGVER}" <.> exeExt
                , _slPVPMajorLinks = False
                , _slSetName = Just $ "haskell-language-server-wrapper" <.> exeExt
                }) : symlinkGhcRules
                )
                False

        s <- get
        if installInfo `elem` s
        then pure ()
        else do
          let vcute = T.unpack $ T.replace "." "" $ prettyVer hlsVer
          modify (installInfo:)
          let header = if null s
                       then "hls-" <> vcute <> "-install-info"
                       else "hls-" <> vcute <> "-" <> prettyShow arch <> "-" <> prettyShow plat <> "-install-info"
          liftIO $ hPutStrLn handle $ "." <> header <> ":"
          liftIO $ hPutStrLn handle $ "  dlInstallInfo: &" <> header
          liftIO $ hPutStrLn handle $ encode' $ installInfo

  pure ExitSuccess
 where
  yamlConfig = YAML.setConfDropNull True YAML.defConfig
  indent i = unlines . map (replicate i ' ' ++) . lines
  encode' = indent 4 . UTF8.toString . YAML.encodePretty yamlConfig

generateHLSGhc :: ( MonadFail m
                  , MonadMask m
                  , Monad m
                  , MonadReader env m
                  , HasSettings env
                  , HasDirs env
                  , HasLog env
                  , MonadThrow m
                  , MonadIO m
                  , MonadUnliftIO m
                  , HasGHCupInfo env
                  )
               => Format
               -> Output
               -> m ExitCode
generateHLSGhc format output = do
  GHCupInfo { _ghcupDownloads = dls } <- getGHCupInfo
  let hlses = dls M.! hls
  r <- forM hlses $ \(unMapIgnoreUnknownKeys  . _viArch -> archs) ->
         forM archs $ \plats ->
           forM (unMapIgnoreUnknownKeys plats) $ \(head . M.toList -> (_, dli)) -> do
             VRight r <- runResourceT . runE
                    @'[DigestError
                      , GPGError
                      , DownloadFailed
                      , UnknownArchive
                      , ArchiveResult
                      , ContentLengthError
                      , URIParseError
                      ] $ do
               fp <- liftE $ downloadCached dli Nothing
               let subd = _dlSubdir dli
               filesL <- liftE $ getArchiveFiles fp
               files <- liftIO $ evaluate $ force filesL
               case subd of
                         Just (RealDir d)
                           | d </> "GNUmakefile" `elem` files
                           -> do let regex = makeRegexOpts compExtended execBlank ([s|^haskell-language-server-([0-9]+\.)*([0-9]+)(\.in)$|] :: ByteString)
                                 pure (rights $ MP.parse version' ""
                                      . T.pack
                                      . fromJust
                                      . stripPrefix "haskell-language-server-"
                                      . stripIn
                                     <$> filter (match regex) (fromJust . stripPrefix (d <> "/") <$> files)
                                      )
                         _ -> do let regex = makeRegexOpts compExtended execBlank ([s|^haskell-language-server-([0-9]+\.)*([0-9]+)(\.exe)?$|] :: ByteString)
                                 pure (rights $ MP.parse version' ""
                                      . T.pack
                                      . fromJust
                                      . stripPrefix "haskell-language-server-"
                                      . stripExe
                                     <$> filter (match regex) files
                                      )
             pure (sort r)
  let w = case format of
            FormatYAML -> BSL.fromStrict $ YAML.encodePretty YAML.defConfig r
            FormatJSON -> Aeson.encodePretty r
  case output of
    StdOut -> liftIO $ BSL.putStr w
    FileOutput f -> liftIO $ BSL.writeFile f w
  pure ExitSuccess
 where
  stripExe :: String -> String
  stripExe f = case reverse f of
                 ('e':'x':'e':'.':r) -> reverse r
                 _ -> f
  stripIn :: String -> String
  stripIn f = case reverse f of
                 ('n':'i':'.':r) -> reverse r
                 _ -> f

generateTable :: ( MonadFail m
                 , MonadMask m
                 , Monad m
                 , MonadReader env m
                 , HasSettings env
                 , HasDirs env
                 , HasLog env
                 , MonadThrow m
                 , MonadIO m
                 , HasPlatformReq env
                 , HasGHCupInfo env
                 , MonadUnliftIO m
                 )
              => Output
              -> m ExitCode
generateTable output = do
  handle <- case output of
              StdOut -> pure stdout
              FileOutput fp -> liftIO $ openFile fp WriteMode

  forM_ [ghc,cabal,hls,stack] $ \tool -> do
    case tool of
      Tool "ghc" -> liftIO $ hPutStrLn handle $ "<details> <summary>Show all supported <a href='https://www.haskell.org/ghc/'>GHC</a> versions</summary>"
      Tool "cabal" -> liftIO $ hPutStrLn handle $ "<details> <summary>Show all supported <a href='https://cabal.readthedocs.io/en/stable/'>cabal-install</a> versions</summary>"
      Tool "hls" -> liftIO $ hPutStrLn handle $ "<details> <summary>Show all supported <a href='https://haskell-language-server.readthedocs.io/en/stable/'>HLS</a> versions</summary>"
      Tool "stack" -> liftIO $ hPutStrLn handle $ "<details> <summary>Show all supported <a href='https://docs.haskellstack.org/en/stable/README/'>Stack</a> versions</summary>"
      _ -> fail "no"
    liftIO $ hPutStrLn handle $ "<table>"
    liftIO $ hPutStrLn handle $ "<thead><tr><th>" <> show tool <> " Version</th><th>Tags</th></tr></thead>"
    liftIO $ hPutStrLn handle $ "<tbody>"
    (VRight vers) <- runE $ listVersions (Just tool) [] False False (Nothing, Nothing)
    forM_ (filter (\ListResult{..} -> not lStray) (reverse vers)) $ \ListResult{..} -> do
      liftIO $ hPutStrLn handle $
          "<tr><td>"
        <> T.unpack (prettyVer lVer)
        <> "</td><td>"
        <> intercalate ", " (filter (/= "") . fmap printTag $ sort lTag)
        <> "</td></tr>"
      pure ()
    liftIO $ hPutStrLn handle $ "</tbody>"
    liftIO $ hPutStrLn handle $ "</table>"
    liftIO $ hPutStrLn handle $ "</details>"
    liftIO $ hPutStrLn handle $ ""
  pure ExitSuccess
 where
  printTag Recommended        = "<span style=\"color:green\">recommended</span>"
  printTag Latest             = "<span style=\"color:blue\">latest</span>"
  printTag Prerelease         = "<span style=\"color:red\">prerelease</span>"
  printTag (Base       pvp'') = "base-" ++ T.unpack (prettyPVP pvp'')
  printTag (UnknownTag t    ) = t
  printTag Old                = ""


generateSystemInfo :: ( MonadFail m
                      , MonadMask m
                      , Monad m
                      , MonadReader env m
                      , HasSettings env
                      , HasDirs env
                      , HasLog env
                      , MonadThrow m
                      , MonadIO m
                      , HasPlatformReq env
                      , HasGHCupInfo env
                      , MonadUnliftIO m
                      )
                   => Output
                   -> m ExitCode
generateSystemInfo output = do
  handle <- case output of
              StdOut -> pure stdout
              FileOutput fp -> liftIO $ openFile fp WriteMode

  forM_ [ Linux Debian
        , Linux Ubuntu
        , Linux Fedora
        , Linux CentOS
        , Linux Alpine
        , Linux UnknownLinux
        , Darwin
        , FreeBSD
        , Windows
        ] $ \plat -> do
            GHCupInfo { .. } <- getGHCupInfo
            (Just req) <- pure $ getCommonRequirements ghc (PlatformResult plat Nothing) _toolRequirements
            liftIO $ hPutStrLn handle $ "### " <> (prettyPlat plat) <> "\n"
            liftIO $ hPutStrLn handle $ (T.unpack $ pretty' req) <> "\n"
  pure ExitSuccess
 where
  pretty' Requirements {..} =
    let d = if not . null $ _distroPKGs
          then "The following distro packages are required: " <> "`" <> T.intercalate " " _distroPKGs <> "`"
          else ""
        n = if not . T.null $ _notes then _notes else ""
    in  if | T.null d -> n
           | T.null n -> d
           | otherwise -> d <> "\n" <> n

  prettyPlat (Linux UnknownLinux) = "Linux (generic)"
  prettyPlat p = show p


generateSystemInfoWithDistroVersion :: ( MonadFail m
                      , MonadMask m
                      , Monad m
                      , MonadReader env m
                      , HasSettings env
                      , HasDirs env
                      , HasLog env
                      , MonadThrow m
                      , MonadIO m
                      , HasPlatformReq env
                      , HasGHCupInfo env
                      , MonadUnliftIO m
                      )
                   => Output
                   -> m ExitCode
generateSystemInfoWithDistroVersion output = do
  handle <- case output of
              StdOut -> pure stdout
              FileOutput fp -> liftIO $ openFile fp WriteMode

  GHCupInfo { _toolRequirements = tr } <- getGHCupInfo
  let ghcInfo = M.lookup Nothing <$> M.lookup ghc tr
  liftIO $ traverse_ (\(key, value)  -> do
                        liftIO $ hPutStrLn handle $ "### " <> prettyPlat key <> "\n"
                        liftIO $ hPutStrLn handle $ T.unpack $ versionsAndRequirements value <> T.pack "\n")
                      $ M.toList $ unMapIgnoreUnknownKeys $ fromJust (fromJust ghcInfo)
  pure ExitSuccess

  where
    pretty' Requirements {..} =
      let d = if not . null $ _distroPKGs
            then "The following distro packages are required: " <> "`" <> T.intercalate " " _distroPKGs <> "`" <> "\n"
            else ""
          n = if not . T.null $ _notes then _notes else ""
      in  if | T.null d -> n
             | T.null n -> d
             | otherwise -> d <> "\n" <> n

    versionsAndRequirements :: PlatformReqVersionSpec -> Text
    versionsAndRequirements =
      bifoldMap
        ( \case
            Nothing -> T.pack $ "#### Generic" <> "\n"
            Just verz -> T.pack "#### Version " <> T.pack (show $ pPrint verz) <> "\n"
        )
        pretty'

    prettyPlat (Linux UnknownLinux) = "Linux (generic)"
    prettyPlat p = show p
