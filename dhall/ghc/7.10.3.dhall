let GHCup = ../ghcup.dhall

let v = "7.10.3"

let baseUrl = "https://downloads.haskell.org/~ghc/${v}"

let archSpec =
      [ { arch = GHCup.Architecture.A_64
        , bindists =
          [ { bindist = "${baseUrl}/ghc-${v}-x86_64-deb8-linux.tar.xz"
            , subdir = "ghc-${v}"
            , hash =
                "91cfbad8dff1e8b34a5fdca8caeaf843b56e36af919e29cd68870d2588563db5"
            , platforms =
              [ { platform = GHCup.Platform.Linux GHCup.LinuxDistro.Debian
                , verRange = [ "unknown_version", ">=3" ]
                }
              , { platform = GHCup.Platform.Linux GHCup.LinuxDistro.Ubuntu
                , verRange = [ "unknown_version" ]
                }
              ]
            }
          , { bindist = "${baseUrl}/ghc-${v}-x86_64-centos7-linux.tar.xz"
            , subdir = "ghc-${v}"
            , hash =
                "01cfbad8dff1e8b34a5fdca8caeaf843b56e36af919e29cd68870d2588563db5"
            , platforms =
              [ { platform = GHCup.Platform.Linux GHCup.LinuxDistro.CentOS
                , verRange = [ "unknown_version" ]
                }
              , { platform = GHCup.Platform.Linux GHCup.LinuxDistro.Ubuntu
                , verRange = [ ">= 20" ]
                }
              ]
            }
          ]
        }
      ]

let ghc7_10_3 =
      GHCup.VersionInfo::{
      , viTags = [ GHCup.Tag.Base "4.18.0.0" ]
      , viChangeLog = Some
          "${baseUrl}/docs/html/users_guide/release-7-10-1.html"
      , viSourceDL = Some GHCup.DownloadInfo::{
        , dlUri = "${baseUrl}/ghc-${v}-src.tar.xz"
        , dlSubdir = Some (GHCup.TarDir.RealDir "ghc-${v}")
        , dlHash = "abc"
        }
      , viTestDL = Some GHCup.DownloadInfo::{
        , dlUri = "${baseUrl}/ghc-${v}-testsuite.tar.xz"
        , dlSubdir = Some (GHCup.TarDir.RealDir "ghc-${v}/testsuite")
        , dlHash = "cdef"
        }
      , viArch = GHCup.mergeArchitectureSpec archSpec
      }

in  ghc7_10_3
