#!/bin/bash

set -eu
set -o pipefail

RELEASE=$1
VERSION=${RELEASE#cabal-install-v}

cd "gh-release-artifacts/cabal-${VERSION}"
BASE_URL=https://downloads.haskell.org/~ghcup/unofficial-bindists/cabal/$VERSION

cat <<EOF > /dev/stdout
    $VERSION:
      viTags:
        - Latest
      viChangeLog: https://github.com/haskell/cabal/blob/master/release-notes/cabal-install-$VERSION.md
      viArch:
        A_64:
          Linux_Debian:
            '< 10': &cabal-${VERSION//./}-64-deb9
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-deb9.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-deb9.tar.xz" | awk '{ print $1 }')
            '(>= 10 && < 11)': &cabal-${VERSION//./}-64-deb10
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-deb10.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-deb10.tar.xz" | awk '{ print $1 }')
            '( >= 11)': &cabal-${VERSION//./}-64-deb11
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-deb11.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-deb11.tar.xz" | awk '{ print $1 }')
            unknown_versioning: *cabal-${VERSION//./}-64-deb9
          Linux_Ubuntu:
            '( >= 16 && < 19 )': &cabal-${VERSION//./}-64-ubuntu18
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-ubuntu18.04.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-ubuntu18.04.tar.xz" | awk '{ print $1 }')
            '( >= 20 && < 22 )': &cabal-${VERSION//./}-64-ubuntu20
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-ubuntu20.04.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-ubuntu20.04.tar.xz" | awk '{ print $1 }')
            '( >= 22 )': &cabal-${VERSION//./}-64-ubuntu22
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-ubuntu22.04.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-ubuntu22.04.tar.xz" | awk '{ print $1 }')
            unknown_versioning: *cabal-${VERSION//./}-64-ubuntu18
          Linux_Mint:
            '(>= 20 && < 21)': &cabal-${VERSION//./}-64-mint20
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-mint20.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-mint20.tar.xz" | awk '{ print $1 }')
            '>= 21': &cabal-${VERSION//./}-64-mint21
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-mint21.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-mint21.tar.xz" | awk '{ print $1 }')
            unknown_versioning: *cabal-${VERSION//./}-64-mint20
          Linux_Fedora:
            '< 33': &cabal-${VERSION//./}-64-fedora27
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-fedora27.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-fedora27.tar.xz" | awk '{ print $1 }')
			'(>= 33 && < 37)': &cabal-${VERSION//./}-64-fedora33
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-fedora33.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-fedora33.tar.xz" | awk '{ print $1 }')
			'>= 37': &cabal-${VERSION//./}-64-fedora37
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-fedora37.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-fedora37.tar.xz" | awk '{ print $1 }')
            unknown_versioning: *cabal-${VERSION//./}-64-fedora27
          Linux_CentOS:
            '( >= 7 && < 8 )': &cabal-${VERSION//./}-64-centos
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-centos7.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-centos7.tar.xz" | awk '{ print $1 }')
            unknown_versioning: *cabal-${VERSION//./}-64-centos
          Linux_Rocky:
            '( >= 8 && < 9 )': &cabal-${VERSION//./}-64-rocky8
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-rocky8.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-rocky8.tar.xz" | awk '{ print $1 }')
            '( >= 9 )': &cabal-${VERSION//./}-64-rocky9
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-rocky9.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-rocky9.tar.xz" | awk '{ print $1 }')
            unknown_versioning: *cabal-${VERSION//./}-64-rocky8
          Linux_RedHat:
            unknown_versioning: *cabal-${VERSION//./}-64-centos
          Linux_UnknownLinux:
            unknown_versioning: &cabal-${VERSION//./}-64-unknown
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-unknown.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-unknown.tar.xz" | awk '{ print $1 }')
          Linux_Alpine:
            '( >= 3.12 && < 3.19 )': &cabal-${VERSION//./}-64-alpine312
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-alpine312.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-alpine312.tar.xz" | awk '{ print $1 }')
            '( >= 3.19 )': &cabal-${VERSION//./}-64-alpine319
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-linux-alpine319.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-linux-alpine319.tar.xz" | awk '{ print $1 }')
            unknown_versioning: *cabal-${VERSION//./}-64-unknown
          Linux_Void:
            unknown_versioning: *cabal-${VERSION//./}-64-unknown
          Darwin:
            unknown_versioning:
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-apple-darwin.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-apple-darwin.tar.xz" | awk '{ print $1 }')
          Windows:
            unknown_versioning:
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-mingw64.zip
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-mingw64.zip" | awk '{ print $1 }')
          FreeBSD:
            unknown_versioning:
              dlUri: ${BASE_URL}/cabal-install-$VERSION-x86_64-portbld-freebsd.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-x86_64-portbld-freebsd.tar.xz" | awk '{ print $1 }')
        A_32:
          Linux_UnknownLinux:
            unknown_versioning: &cabal-${VERSION//./}-32-unknown
              dlUri: ${BASE_URL}/cabal-install-$VERSION-i386-linux-unknown.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-i386-linux-unknown.tar.xz" | awk '{ print $1 }')
          Linux_Alpine:
            unknown_versioning: *cabal-${VERSION//./}-32-unknown
        A_ARM64:
          Linux_UnknownLinux:
            unknown_versioning:
              dlUri: ${BASE_URL}/cabal-install-$VERSION-aarch64-linux-deb10.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-aarch64-linux-deb10.tar.xz" | awk '{ print $1 }')
          Darwin:
            unknown_versioning:
              dlUri: ${BASE_URL}/cabal-install-$VERSION-aarch64-apple-darwin.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-aarch64-apple-darwin.tar.xz" | awk '{ print $1 }')
        A_ARM:
          Linux_UnknownLinux:
            unknown_versioning:
              dlUri: ${BASE_URL}/cabal-install-$VERSION-armv7-linux-deb10.tar.xz
              dlHash: $(sha256sum "cabal-install-$VERSION-armv7-linux-deb10.tar.xz" | awk '{ print $1 }')
EOF

