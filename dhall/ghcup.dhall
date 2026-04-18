let Prelude =
      https://prelude.dhall-lang.org/v23.1.0/package.dhall
        sha256:931cbfae9d746c4611b07633ab1e547637ab4ba138b16bf65ef1b9ad66a60b7f

let Day = Date

let PVP = Text

let URI = Text

let Tool = Text

let Version = Text

let VersionRange = Text

let GHCTargetVersion = Text

let Map = Prelude.Map.Type

let PlatformText = Text

let ArchitectureText = Text

let Tag =
      < Latest
      | Recommended
      | Prerelease
      | LatestPrerelease
      | Nightly
      | LatestNightly
      | Base : PVP
      | Old
      | Experimental
      | UnknownTag : Text
      >

let LinuxDistro =
      < Debian
      | Ubuntu
      | Mint
      | Fedora
      | CentOS
      | RedHat
      | Alpine
      | AmazonLinux
      | Rocky
      | Void
      | Gentoo
      | Exherbo
      | OpenSUSE
      | UnknownLinux
      >

let distroToNatural
    : LinuxDistro → Natural
    = λ(d : LinuxDistro) →
        merge
          { Debian = 1
          , Ubuntu = 2
          , Mint = 3
          , Fedora = 4
          , CentOS = 5
          , RedHat = 6
          , Alpine = 7
          , AmazonLinux = 8
          , Rocky = 9
          , Void = 10
          , Gentoo = 11
          , Exherbo = 12
          , OpenSUSE = 13
          , UnknownLinux = 14
          }
          d

let distroToText
    : LinuxDistro → Text
    = λ(d : LinuxDistro) →
        merge
          { Debian = "Debian"
          , Ubuntu = "Ubuntu"
          , Mint = "Mint"
          , Fedora = "Fedora"
          , CentOS = "CentOS"
          , RedHat = "Redhat"
          , Alpine = "Alpine"
          , AmazonLinux = "AmazonLinux"
          , Rocky = "Rocky"
          , Void = "Void"
          , Gentoo = "Gentoo"
          , Exherbo = "Exherbo"
          , OpenSUSE = "OpenSUSE"
          , UnknownLinux = "UnknownLinux"
          }
          d

let Platform = < Linux : LinuxDistro | Darwin | FreeBSD | OpenBSD | Windows >

let platformToText
    : Platform → Text
    = λ(p : Platform) →
        merge
          { Linux = λ(d : LinuxDistro) → "Linux_" ++ distroToText d
          , Darwin = "Darwin"
          , FreeBSD = "FreeBSD"
          , OpenBSD = "OpenBSD"
          , Windows = "Windows"
          }
          p

let platformToNatural
    : Platform → Natural
    = λ(p : Platform) →
        merge
          { Linux = λ(d : LinuxDistro) → 5 + distroToNatural d
          , Darwin = 1
          , FreeBSD = 2
          , OpenBSD = 3
          , Windows = 4
          }
          p

let Architecture =
      < A_64
      | A_32
      | A_PowerPC
      | A_PowerPC64
      | A_Sparc
      | A_Sparc64
      | A_ARM
      | A_ARM64
      >

let archToText
    : Architecture → Text
    = λ(a : Architecture) →
        merge
          { A_64 = "x86_64"
          , A_32 = "i386"
          , A_PowerPC = "powerpc"
          , A_PowerPC64 = "powerpc64"
          , A_Sparc = "sparc"
          , A_Sparc64 = "sparc64"
          , A_ARM = "arm"
          , A_ARM64 = "aarch64"
          }
          a

let EnvUnion = < PreferSystem | PreferSpec | OnlySpec >

let EnvSpec = { env : List { _1 : Text, _2 : Text }, union : EnvUnion }

let ConfigSpec =
      { configFile : Optional Text
      , configEnv : Optional EnvSpec
      , configArgs : List Text
      }

let MakeSpec = { makeEnv : Optional EnvSpec, makeArgs : List Text }

let InstallFileRule =
      < InstallFileRule : { installSource : Text, installDest : Optional Text }
      | InstallFilePatternRule : { installPattern : List Text }
      >

let SymlinkSpec =
      { target : Text
      , linkName : Text
      , pVPMajorLinks : Bool
      , setName : Optional Text
      }

let InstallationSpec =
      { exeRules : List InstallFileRule
      , dataRules : List InstallFileRule
      , exeSymLinked : List SymlinkSpec
      , configure : Optional ConfigSpec
      , make : Optional MakeSpec
      , preserveMtimes : Bool
      }

let TarDir = < RealDir : Text | RegexDir : Text >

let Requirements = { distroPKGs : List Text, notes : Text }

let DownloadInfo =
      { Type =
          { dlUri : Text
          , dlSubdir : Optional TarDir
          , dlHash : Text
          , dlCSize : Optional Integer
          , dlOutput : Optional Text
          , dlTag : Optional (List Tag)
          , dlInstallSpec : Optional InstallationSpec
          }
      , default =
        { dlUri = ""
        , dlSubdir = None TarDir
        , dlHash = ""
        , dlCSize = None Integer
        , dlInstallSpec = None InstallationSpec
        , dlOutput = None Text
        , dlTag = None (List Tag)
        }
      }

let PlatformVersionSpec = Map VersionRange DownloadInfo.Type

let PlatformSpec = Map Platform PlatformVersionSpec

let PlatformValueSpec = Map Text PlatformVersionSpec

let ArchitectureSpec = Map Architecture PlatformSpec

let ArchitectureValueSpec = Map Text PlatformValueSpec

let VersionInfo =
      { Type =
          { viTags : List Tag
          , viReleaseDay : Optional Day
          , viChangeLog : Optional URI
          , viSourceDL : Optional DownloadInfo.Type
          , viTestDL : Optional DownloadInfo.Type
          , viArch : ArchitectureValueSpec
          , viPreInstall : Optional Text
          , viPostInstall : Optional Text
          , viPostRemove : Optional Text
          , viPreCompile : Optional Text
          }
      , default =
        { viTags = [] : List Tag
        , viReleaseDay = None Day
        , viChangeLog = None URI
        , viSourceDL = None DownloadInfo.Type
        , viTestDL = None DownloadInfo.Type
        , viArch = [] : ArchitectureSpec
        , viPreInstall = None Text
        , viPostInstall = None Text
        , viPostRemove = None Text
        , viPreCompile = None Text
        }
      }

let ToolRequirements =
      Map Tool (Map Version (Map PlatformText (Map Text Requirements)))

let ToolVersionSpec = Map GHCTargetVersion VersionInfo.Type

let GHCupDownloads = Map Tool ToolVersionSpec

let GHCupInfo =
      { toolRequirements : ToolRequirements
      , ghcupDownloads : GHCupDownloads
      , metadataUpdate : Optional URI
      }

let Bindist =
      { bindist : Text
      , subdir : Text
      , hash : Text
      , platforms : List { platform : Platform, verRange : List Text }
      }

let ArchBindist = { arch : Architecture, bindists : List Bindist }

let ghcBaseVi =
      λ(v : Text) →
      λ(baseUrl : Text) →
      λ(tags : List Tag) →
      λ(srcHash : Text) →
      λ(testHash : Text) →
      λ(archSpec : ArchitectureValueSpec) →
        VersionInfo::{
        , viTags = tags
        , viChangeLog = Some
            "${baseUrl}/docs/html/users_guide/release-7-10-1.html"
        , viSourceDL = Some DownloadInfo::{
          , dlUri = "${baseUrl}/ghc-${v}-src.tar.xz"
          , dlSubdir = Some (TarDir.RealDir "ghc-${v}")
          , dlHash = "${srcHash}"
          }
        , viTestDL = Some DownloadInfo::{
          , dlUri = "${baseUrl}/ghc-${v}-testsuite.tar.xz"
          , dlSubdir = Some (TarDir.RealDir "ghc-${v}/testsuite")
          , dlHash = "${testHash}"
          }
        , viArch = archSpec
        }

let ghcDownload =
      λ(v : Text) →
      λ(baseUrl : Text) →
      λ(arch : Architecture) →
      λ(platform : Platform) →
      λ(versionRange : VersionRange) →
      λ(hash : Text) →
      λ(ext : Text) →
        let archText = archToText arch

        let platformText = platformToText platform

        in  [ { mapKey = "${versionRange}"
              , mapValue = DownloadInfo::{
                , dlUri =
                    "${baseUrl}/ghc-${v}-${archText}-${platformText}.${ext}"
                , dlSubdir = Some (TarDir.RealDir "ghc-${v}")
                , dlHash = "${hash}"
                }
              }
            ]

let toKeyValueMap =
      λ(k : Type) →
      λ(v : Type) →
      λ(f : k → Text) →
      λ(list : List { mapKey : k, mapValue : v }) →
        Prelude.List.map
          { mapKey : k, mapValue : v }
          { mapKey : Text, mapValue : v }
          ( λ(m : { mapKey : k, mapValue : v }) →
              { mapKey = f m.mapKey, mapValue = m.mapValue }
          )
          list

let mergePlatformSpec =
      λ(platforms : List { platform : Platform, verRange : List Text }) →
      λ(bindist : Text) →
      λ(dlSubdir : Text) →
      λ(hash : Text) →
      λ(acc : PlatformSpec) →
        Prelude.List.fold
          { platform : Platform, verRange : List Text }
          platforms
          PlatformSpec
          ( λ(a : { platform : Platform, verRange : List Text }) →
            λ(b : PlatformSpec) →
              let newPlat =
                    { mapKey = a.platform
                    , mapValue =
                        Prelude.List.map
                          Text
                          { mapKey : VersionRange
                          , mapValue : DownloadInfo.Type
                          }
                          ( λ(vr : Text) →
                              { mapKey = vr
                              , mapValue = DownloadInfo::{
                                , dlUri = "${bindist}"
                                , dlSubdir = Some (TarDir.RealDir "${dlSubdir}")
                                , dlHash = "${hash}"
                                }
                              }
                          )
                          a.verRange
                    }

              in  if    Prelude.List.any
                          { mapKey : Platform, mapValue : PlatformVersionSpec }
                          ( λ ( l
                              : { mapKey : Platform
                                , mapValue : PlatformVersionSpec
                                }
                              ) →
                              Prelude.Natural.equal
                                (platformToNatural l.mapKey)
                                (platformToNatural newPlat.mapKey)
                          )
                          b
                  then  Prelude.List.map
                          { mapKey : Platform, mapValue : PlatformVersionSpec }
                          { mapKey : Platform, mapValue : PlatformVersionSpec }
                          ( λ ( l
                              : { mapKey : Platform
                                , mapValue : PlatformVersionSpec
                                }
                              ) →
                              if    Prelude.Natural.equal
                                      (platformToNatural l.mapKey)
                                      (platformToNatural newPlat.mapKey)
                              then  { mapKey = l.mapKey
                                    , mapValue = l.mapValue # newPlat.mapValue
                                    }
                              else  l
                          )
                          b
                  else  [ newPlat ] # b
          )
          (acc : PlatformSpec)

let mergeArchitectureSpec =
      λ(archBindists : List ArchBindist) →
        let archSpec =
              Prelude.List.fold
                ArchBindist
                archBindists
                (List { mapKey : Architecture, mapValue : PlatformSpec })
                ( λ(a : ArchBindist) →
                  λ ( p
                    : List { mapKey : Architecture, mapValue : PlatformSpec }
                    ) →
                    let platformSpec =
                          Prelude.List.fold
                            Bindist
                            a.bindists
                            PlatformSpec
                            ( λ(b : Bindist) →
                              λ(acc : PlatformSpec) →
                                mergePlatformSpec
                                  b.platforms
                                  b.bindist
                                  b.subdir
                                  b.hash
                                  acc
                            )
                            ([] : PlatformSpec)

                    in  [ { mapKey = a.arch, mapValue = platformSpec } ] # p
                )
                ([] : List { mapKey : Architecture, mapValue : PlatformSpec })

        in  toKeyValueMap
              Architecture
              PlatformValueSpec
              archToText
              ( Prelude.Map.map
                  Architecture
                  PlatformSpec
                  PlatformValueSpec
                  (toKeyValueMap Platform PlatformVersionSpec platformToText)
                  archSpec
              )

in  { Tag
    , LinuxDistro
    , Platform
    , Architecture
    , EnvUnion
    , EnvSpec
    , ConfigSpec
    , MakeSpec
    , InstallFileRule
    , SymlinkSpec
    , InstallationSpec
    , TarDir
    , Requirements
    , DownloadInfo
    , VersionInfo
    , GHCupInfo
      -- Aliases
    , Day
    , PVP
    , URI
    , Tool
    , Version
    , VersionRange
    , GHCTargetVersion
    , PlatformText
    , ArchitectureText
    , ToolRequirements
    , ToolVersionSpec
    , GHCupDownloads
    , PlatformVersionSpec
    , PlatformSpec
    , PlatformValueSpec
    , ArchitectureSpec
    , ArchitectureValueSpec
    , Bindist
    , ArchBindist
      -- functions
    , distroToText
    , distroToNatural
    , platformToText
    , platformToNatural
    , archToText
    , ghcBaseVi
    , ghcDownload
    , toKeyValueMap
    , mergePlatformSpec
    , mergeArchitectureSpec
    }
