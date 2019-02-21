#! /usr/bin/env bash

source common.sh

for f in "$CREW_PKG_PATH"/*.rb; do
  name="$(basename "$f" | sed 's/.rb$//')"
  msg "Importing '%s'..." "$name"
  ./mutiny.sh "$name"
done
