#! /usr/bin/env bash

set -e

CREW_PKG_PATH="$(crew const CREW_LIB_PATH | cut -d= -f2)/packages"

crewname="$1"

if [[ -z "$crewname" ]]; then
  echo "Usage: $0 <pkgname>"
  exit 1
fi

pkgfile="$CREW_PKG_PATH/$crewname.rb"

if [[ ! -f "$pkgfile" ]]; then
  echo "Unknown package: $crewname"
  exit 1
fi

while read -r line; do
  case $line in
    description*)
      pkgdesc="$(echo "$line" | sed -E "s/.*description.*['\"](.+)['\"].*/\1/")"
      ;;
    homepage*)
      url="$(echo "$line" | sed -E "s/.*homepage.*['\"](.+)['\"].*/\1/")"
      ;;
    version*)
      crewver="$(echo "$line" | sed -E "s/.*version.*['\"](.+)['\"].*/\1/")"
      ;;
  esac
done < "$pkgfile"

pkgname=$(echo "$crewname" | sed 's/_/-/g')
pkgver=$(echo "$crewver" | sed -E 's/([0-9\.]+).*/\1/')

curl -so /tmp/package.json "https://www.archlinux.org/packages/core/x86_64/$pkgname/json/"
if ! (jq -r '.' /tmp/package.json &> /dev/null); then
  curl -so /tmp/package.json "https://www.archlinux.org/packages/core/any/$pkgname/json/"
fi

if (jq -r '.' /tmp/package.json &> /dev/null); then
  pkgdesc="$(jq -r '.pkgdesc' /tmp/package.json)"
  url="$(jq -r '.url' /tmp/package.json)"
  licenses="$(jq -r '.licenses | map("'"'"'" + . + "'"'"'") | join(" ")' /tmp/package.json)"
  groups="$(jq -r '.groups | map("'"'"'" + . + "'"'"'") | join(" ")' /tmp/package.json)"
  depends="$(jq -r '.depends | map("'"'"'" + . + "'"'"'") | join(" ")' /tmp/package.json)"
  makedepends="$(jq -r '.makedepends | map("'"'"'" + . + "'"'"'") | join(" ")' /tmp/package.json)"
  optdepends="$(jq -r '.optdepends | map("'"'"'" + . + "'"'"'") | join(" ")' /tmp/package.json)"
  provides="$(jq -r '.provides | map("'"'"'" + . + "'"'"'") | join(" ")' /tmp/package.json)"
  conflicts="$(jq -r '.conflicts | map("'"'"'" + . + "'"'"'") | join(" ")' /tmp/package.json)"
  replaces="$(jq -r '.replaces | map("'"'"'" + . + "'"'"'") | join(" ")' /tmp/package.json)"
fi

rm -f /tmp/package.json

mkdir -p "packages/$pkgname"
cat > "packages/$pkgname/PKGBUILD" <<EOF
# Maintainer: $(git config --get user.name) <$(git config --get user.email)>

pkgname=$pkgname
_pkgname=$crewname
pkgver=$pkgver
_pkgver=$pkgver
pkgrel=1
pkgdesc="$pkgdesc"
arch=('x86_64')
url="$url"
license=($licenses)
groups=($groups)
depends=($depends)
makedepends=($makedepends)
optdepends=($optdepends)
provides=($provides)
conflicts=($conflicts)
replaces=($replaces)
backup=()
options=()
source=("https://dl.bintray.com/chromebrew/chromebrew/\$_pkgname-\$_pkgver-chromeos-x86_64.tar.xz")
sha256sums=('abc')

package() {
  cp -a usr "\$pkgdir"
}
EOF

(cd "packages/$pkgname" && updpkgsums)
