let Prelude =
      https://prelude.dhall-lang.org/v23.1.0/package.dhall
        sha256:931cbfae9d746c4611b07633ab1e547637ab4ba138b16bf65ef1b9ad66a60b7f

let GHCup = ./ghcup.dhall

let ghc7_10_3 = ./ghc/7.10.3.dhall

let ghc_versions
    : List { versionInfo : GHCup.VersionInfo.Type, ver : Text }
    = [ { versionInfo = ghc7_10_3, ver = "7.10.3" } ]

let ghcs
    : GHCup.ToolVersionSpec
    = Prelude.List.fold
        { versionInfo : GHCup.VersionInfo.Type, ver : Text }
        ghc_versions
        GHCup.ToolVersionSpec
        ( λ(a : { versionInfo : GHCup.VersionInfo.Type, ver : Text }) →
          λ(b : GHCup.ToolVersionSpec) →
              [ Prelude.Map.keyValue
                  GHCup.VersionInfo.Type
                  "${a.ver}"
                  a.versionInfo
              ]
            # b
        )
        ([] : GHCup.ToolVersionSpec)

in  ghcs
