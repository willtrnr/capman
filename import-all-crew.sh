#! /usr/bin/env bash

# Import the makepkg utils for logging
source /usr/local/share/makepkg/util.sh
colorize

# Set the crew package folder path
CREW_PKG_PATH="$(crew const CREW_LIB_PATH | cut -d= -f2)/packages"

for f in "$CREW_PKG_PATH"/*.rb; do
  name="$(basename "$f" | sed 's/.rb$//')"
  msg "Importing '%s'..." "$name"
  ./mutiny.sh "$name"
done
