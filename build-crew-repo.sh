#! /usr/bin/env bash

source common.sh

REPO_NAME="${REPO_NAME:-crew}"
REPO_PATH="./repo/$REPO_NAME/os/x86_64"
REPO_DB="$REPO_PATH/$REPO_NAME.db.tar.gz"

if [ -d "$REPO_PATH" ]; then
  msg "Removing current repo files..."
  rm -rf "$REPO_PATH"
fi

mkdir -p "$REPO_PATH"

for pkg in "$MUTINY_PKG_PATH/"*; do
  name="$(basename "$pkg")"
  if (grep -q 'build()' "$pkg/PKGBUILD"); then
    warning "Skipping '%s' due to build requirement." "$name"
  else
    msg "Building '%s'..." "$name"
    (cd "$pkg"; makepkg -d --sign)

    msg "Adding package '%s' to the repo..." "$name"
    repo-add "$REPO_DB" "$pkg/$name-"*.pkg.tar.xz
    cp "$pkg/$name-"*.pkg.tar.xz{,.sig} "$REPO_PATH"

    msg "Cleaning up..."
    for f in "$pkg/"*; do
      if [ "$(basename "$f")" != PKGBUILD ] && [[ "$f" != *.pkg.tar.xz* ]]; then
        rm -rf "$f"
      fi
    done
  fi
done
