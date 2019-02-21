#! /usr/bin/env bash

set -e

source common.sh

# Check proper usage
crewname="$1"
if [ -z "$crewname" ]; then
  printf "Usage: %s <crew package>" "$0"
  exit 1
fi

# Verify the package exists in crew
crewpkg="$CREW_PKG_PATH/$crewname.rb"
if [ ! -f "$crewpkg" ]; then
  error "Unknown package: %s" "$crewname"
  exit 1
fi


msg "Parsing the crew package file..."

pkgname="$(sanitize_name "$crewname")"
depends=()
makedepends=()

# Line by line we try to extract the fields that are useful to us
_in_sources=0
_in_sums=0
while read -r line; do
  case $line in
    description*)
      pkgdesc="$(echo "$line" | sed -E "s/^.*description.*['\"](.+)['\"].*$/\1/")"
      ;;
    homepage*)
      url="$(echo "$line" | sed -E "s/^.*homepage.*['\"](.+)['\"].*$/\1/")"
      ;;
    version*)
      crewver="$(echo "$line" | sed -E "s/^.*version.*['\"](.+)['\"].*$/\1/")"
      ;;
    binary_url*)
      _in_sources=1
      _in_sums=0
      ;;
    binary_sha256*)
      _in_sums=1
      _in_sources=0
      ;;
    x86_64*)
      if [ $_in_sources -eq 1 ]; then
        binary_url="\"$(echo "$line" | sed -E "s/^.*:.*['\"](.+)['\"].*$/\1/")\""
      elif [ $_in_sums -eq 1 ]; then
        binary_sha256="'$(echo "$line" | sed -E "s/^.*:.*['\"](.+)['\"].*$/\1/")'"
      fi
      ;;
    '})')
      _in_sources=0
      _in_sums=0
      ;;
    depends_on*)
      name="$(sanitize_name "$(echo "$line" | sed -E "s/^[^'\"]*['\"]([^'\"]+)['\"].*$/\1/")")"
      if [[ "$line" == *:build ]]; then
        makedepends+=("'$name'")
      else
        depends+=("'$name'")
      fi
      ;;
  esac
done < "$crewpkg"

# Crew sometimes have pkgrels embedded in the version number
pkgver="${crewver%%-*}"
pkgrel=1
if [[ "$crewver" == *-* ]]; then
  pkgrel="${crewver##*-}"
fi


msg "Fetching Arch package details for %s..." "$pkgname"

# Find the package using exact name match on the Arch repository API
if (curl -s "https://www.archlinux.org/packages/search/json/?name=$pkgname" | jq -e -r '.results[0]' > "/tmp/$pkgname.json" 2> /dev/null); then
  # Extract and possibly override the info we have so far
  pkgdesc="$(jq -r '.pkgdesc' "/tmp/$pkgname.json")"
  url="$(jq -r '.url' "/tmp/$pkgname.json")"
  licenses="$(jq -r '.licenses | map("'"'"'" + . + "'"'"'") | join(" ")' "/tmp/$pkgname.json")"
  groups="$(jq -r '.groups | map("'"'"'" + . + "'"'"'") | join(" ")' "/tmp/$pkgname.json")"
  # unset depends
  # depends="$(jq -r '.depends | map("'"'"'" + . + "'"'"'") | join(" ")' "/tmp/$pkgname.json")"
  # unset makedepends
  # makedepends="$(jq -r '.makedepends | map("'"'"'" + . + "'"'"'") | join(" ")' "/tmp/$pkgname.json")"
  # optdepends="$(jq -r '.optdepends | map("'"'"'" + . + "'"'"'") | join("\n            ")' "/tmp/$pkgname.json")"
  # provides="$(jq -r '.provides | map("'"'"'" + . + "'"'"'") | join(" ")' "/tmp/$pkgname.json")"
  # conflicts="$(jq -r '.conflicts | map("'"'"'" + . + "'"'"'") | join(" ")' "/tmp/$pkgname.json")"
  # replaces="$(jq -r '.replaces | map("'"'"'" + . + "'"'"'") | join(" ")' "/tmp/$pkgname.json")"
else
  # We'll produce the package as-is
  warning "No equivalent package found, will use crew information."
fi
rm -f "/tmp/$pkgname.json"


destdir="$MUTINY_PKG_PATH/$pkgname"

msg "Writing the new PKGBUILD to %s..." "$destdir"

if [ -z "$binary_url" ]; then
  warning "No binary package is available, will build from sources."
  build="
build() {
  yes | crew build "$crewname"
  tar xf \"$crewname-$crewver-chromeos-\$arch.tar.xz\"
}
"
else
  # If we're using binaries we don't need makedepends
  unset makedepends
fi

mkdir -p "$destdir"
cat > "$destdir/PKGBUILD" <<EOF
# Maintainer: $(git config --get user.name) <$(git config --get user.email)>

pkgname=$pkgname
pkgver=$pkgver
pkgrel=$pkgrel
pkgdesc="$pkgdesc"
arch=('x86_64')
url="$url"
license=(${licenses:-'custom'})
groups=($groups)
depends=(${depends[@]})
makedepends=(${makedepends[@]})
optdepends=($optdepends)
provides=($provides)
conflicts=($conflicts)
replaces=($replaces)
source=($binary_url)
sha256sums=($binary_sha256)
$build
package() {
  install -d -m 0755 "\$pkgdir/usr"
  cp -a usr/local "\$pkgdir/usr"
}
EOF
