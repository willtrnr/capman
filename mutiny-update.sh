#! /usr/bin/env sh

for f in ./crew/*; do
  ./mutiny.sh "$(basename "$f" | sed 's/-/_/g')"
done
