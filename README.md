# GHCup metadata

This repo is a collection of different GHCup metadata. These are mappings from tool versions (e.g. GHC 9.6.5)
to bindist URLs (e.g. https://downloads.haskell.org/~ghc/9.6.5/ghc-9.6.5-x86_64-fedora33-linux.tar.xz), depending
on architecture (e.g. X86_64), platform (e.g Linux) and possibly distro (e.g. Fedora).

## For end users

### Metadata variants (distribution channels)

* `ghcup-A.B.C.yaml`: this is the main metadata and what ghcup uses by default
* `ghcup-vanilla-A.B.C.yaml`: this is similar to `ghcup-A.B.C.yaml`, but only uses upstream bindists (no patches/fixes are applied, no missing platforms added)
* `ghcup-prereleases-A.B.C.yaml`: this contains pre-releases of all tools
* `ghcup-cross-A.B.C.yaml`: this contains experimental cross compilers. See https://www.haskell.org/ghcup/guide/#cross-support for details.

### Using the metadata

If you want access to both pre-releases and cross compilers, run:

```
ghcup config add-release-channel https://raw.githubusercontent.com/haskell/ghcup-metadata/master/ghcup-prereleases-0.0.7.yaml
ghcup config add-release-channel https://raw.githubusercontent.com/haskell/ghcup-metadata/master/ghcup-cross-0.0.8.yaml
```

If you want **only** vanilla upstream bindists and opt out of all unofficial stuff, you'd run:

```sh
ghcup config set url-source https://raw.githubusercontent.com/haskell/ghcup-metadata/master/ghcup-vanilla-0.0.8.yaml
```

Also check the [config.yaml documentation](https://github.com/haskell/ghcup-hs/blob/master/data/config.yaml).

## Contributions

### The default channel (`ghcup-A.B.C.yaml`)

This channel is strictly maintained by the GHCup project.
Most bindists here are built downstream by the GHCup developers, e.g.:

* https://github.com/stable-haskell/haskell-language-server
* https://github.com/stable-haskell/cabal
* https://github.com/stable-haskell/stack

For GHC bindists there is no automation yet and it is done manually (e.g. for FreeBSD and Alpine i386).

You can suggest updates to tool versions via raising an issue or a PR.

### The vanilla channel (`ghcup-vanilla-A.B.C.yaml`)

These are technically maintained by the upstream developers (GHC, HLS, cabal and stack developers).
GHCup developers do not interfere with decisions in general and do only little QA.

You can suggest updates to tool versions via raising an issue or a PR, but you may also want to CC
some of the upstream developers.

For GHC:

- @bgamari
- @mpickering
- @wz1000

For Cabal:

- @Kleidukos
- @geekosaur
- @Mikolaj

For Stack:

- @mpilgrem

For HLS:

- @wz1000
- @michaelpj

### Other channels

Other channels are maintained in collaboration.

### Understanding tags

Tags are documented [here](https://github.com/haskell/ghcup-hs/blob/master/lib/GHCup/Types.hs). Search for `data Tag`.
Some tags are unique. Uniqueness is checked by `cabal run ghcup-gen -- check -f ghcup-<yaml-ver>.yaml`.

If you want to check prereleases, do: `cabal run ghcup-gen -- check -f ghcup-prereleases-<yaml-ver>.yaml --channel=prerelease`

### During a PR

The following things are relevant when raising a PR.

#### ghcup-gen

`ghcup-gen` is a cabal project that lives in this repository to aid with various metadata tasks.
Run `cabal run ghcup-gen -- --help` for more information.

To test that the yaml is valid and certain tags are unique, you can run:

```sh
cabal run ghcup-gen -- check -f ghcup-0.0.8.yaml
```

To test that all bindists you just added are fetchable, you can run e.g.:

```sh
cabal run ghcup-gen -- check-tarballs -f ghcup-0.0.8.yaml -u 'ghc-9\.6\.6'
```

#### Bindist CI

There is a manual workflow that runs smoke tests on all supported platforms against a tool version (e.g. installing GHC and compiling a
hello world): https://github.com/haskell/ghcup-metadata/actions/workflows/bindists.yaml

To execute it your branch must exist on the main repository and you must have privileges to the repository.
If you don't, ask the ghcup maintainer or some of the listed upstream maintainers.

Some of the failures are expected (e.g. armv7 on GHC).

#### GPG signing

- make sure to sign the yaml files you edited, e.g.: `gpg --detach-sign -u <your-email> ghcup-0.0.8.yaml` or ask a GHCup developer to sign
- PGP pubkeys need to be cross-signed by the GHCup team
- they need to be added to the CI: https://github.com/haskell/ghcup-metadata/blob/develop/.github/workflows/sigs
- and need to be documented on the homepage
  * https://github.com/haskell/ghcup-hs/blob/master/docs/guide.md#gpg-verification
  * https://github.com/haskell/ghcup-hs/blob/master/docs/install.md#unix

