#! /usr/bin/env bash

for f in ./{core,crew}/*/*; do
  name="$(basename "$f")"
  if [ "$name" = pkg ] || [ "$name" = src ] || [[ "$name" == *.tar* ]]; then
    rm -rf "$f"
  fi
done
