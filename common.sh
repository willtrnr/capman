#! /usr/bin/env bash

# Import the makepkg utils for logging
source /usr/local/share/makepkg/util.sh
colorize

# Set the crew package folder path
CREW_PKG_PATH="$(crew const CREW_LIB_PATH | cut -d= -f2)/packages"

# Set a default for our mutiny packages path
MUTINY_PKG_PATH="${MUTINY_PKG_PATH:-./crew}"

# Set a default for the override files path
MUTINY_OVERRIDE_PATH="${MUTINY_OVERRIDE_PATH:-./mutiny-override}"

# Sanitize a package name using override or regular cleanup
sanitize_name() {
  local name="$1"
  if [ -f "$MUTINY_OVERRIDE_PATH/$name.pkgname" ]; then
    # Read the name from the override file
    cat "$MUTINY_OVERRIDE_PATH/$name.pkgname"
  else
    # Sanitize the name for use in a PKGBUILD
    echo "${name//_/-}"
  fi
}
