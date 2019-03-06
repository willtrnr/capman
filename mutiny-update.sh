#! /usr/bin/env bash

source common.sh

REPO_NAME="${REPO_NAME:-crew}"
REPO_PATH="./repo/$REPO_NAME/os/x86_64"
REPO_DB="$REPO_PATH/$REPO_NAME.db.tar.gz"

for pkg in "$MUTINY_PKG_PATH/"*; do
  pkgname="$(basename "$pkg")"
  pkgver="$(grep pkgver "$pkg/PKGBUILD" | cut -d= -f2)"
  pkgrel="$(grep pkgrel "$pkg/PKGBUILD" | cut -d= -f2)"

  crewname="${pkgname//-/_}"
  if [ -f "$CREW_PKG_PATH/$crewname.rb" ]; then
    crewver="$(grep '^\s*version' "$CREW_PKG_PATH/$crewname.rb" | head -n1 | sed -E "s/^.*version.*['\"](.+)['\"].*$/\1/")"

    # Crew sometimes have pkgrels embedded in the version number
    newver="$(sanitize_ver "$crewver")"
    newrel="$(sanitize_rel "$crewver")"

    if [ "$pkgver-$pkgrel" != "$newver-$newrel" ]; then
      msg "Updating package '%s' from '%s' to '%s'..." "$pkgname" "$pkgver-$pkgrel" "$newver-$newrel"
      ./mutiny.sh "$crewname"

      if (grep -q 'build()' "$pkg/PKGBUILD"); then
        warning "Not building '%s' due to no binaries available." "$pkgname"
      else
        msg "Building '%s'..." "$pkgname"
        (cd "$pkg"; makepkg -d --sign)

        msg "Removing old version of package '%s' from the repo..." "$pkgname"
        rm -f "$REPO_PATH/$pkgname-$pkgver-$pkgrel-"*

        msg "Adding package '%s' to the repo..." "$pkgname"
        for f in "$pkg/$pkgname-$newver-$newrel-"*.pkg.tar.xz{,.sig}; do
          ln "$f" "$REPO_PATH/$(basename "$f")"
        done
        repo-add "$REPO_DB" "$pkg/$pkgname-$newver-$newrel-"*.pkg.tar.xz

        msg "Cleaning up..."
        for f in "$pkg/"*; do
          if [ "$(basename "$f")" != PKGBUILD ] && [[ "$f" != *.pkg.tar.xz* ]]; then
            rm -rf "$f"
          fi
        done
      fi
    else
      msg "Package '%s' is up to date." "$pkgname"
    fi
  fi
done
