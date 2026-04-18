let Prelude = https://prelude.dhall-lang.org/v23.1.0/package.dhall
  sha256:931cbfae9d746c4611b07633ab1e547637ab4ba138b16bf65ef1b9ad66a60b7f
let GHCup = ./ghcup.dhall
let ghcs = ./ghc.dhall

in { toolRequirements = [] : GHCup.ToolRequirements
   , metadataUpdate = None GHCup.URI
   , ghcupDownloads = [
       Prelude.Map.keyValue GHCup.ToolVersionSpec "ghc" ghcs
     ]
}
