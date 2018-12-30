#! /usr/bin/env bash

# Import the makepkg utils for logging
source /usr/local/share/makepkg/util.sh
colorize

REPO_NAME="${REPO_NAME:-crew}"
REPO_PATH="./repo/$REPO_NAME/os/x86_64"
REPO_DB="$REPO_PATH/$REPO_NAME.db.tar.gz"

# Set a default for our mutiny packages path
MUTINY_PKG_PATH="${MUTINY_PKG_PATH:-./crew}"

if [ -d "$REPO_PATH" ]; then
  msg "Removing current repo files..."
  rm -rf "$REPO_PATH"
fi

mkdir -p "$REPO_PATH"

for pkg in ./crew/*; do
  name="$(basename "$pkg")"

  msg "Building '%s'..." "$name"
  (cd "$pkg"; makepkg -d)

  msg "Adding package '%s' to the repo..." "$name"
  repo-add "$REPO_DB" "$pkg/$name-"*.pkg.tar.xz
  cp "$pkg/$name-"*.pkg.tar.xz "$REPO_PATH"

  msg "Cleaning up..."
  for f in "$pkg/"*; do
    if [ "$(basename "$f")" != PKGBUILD ] && [[ "$f" != *.pkg.tar.xz ]]; then
      rm -r "$f"
    fi
  done
done
