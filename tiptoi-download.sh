#!/bin/bash

set -e

BASE="https://www.ravensburger.de"

query="$1"

if [ -z "$query" ]; then
  echo "No searchquery supplied!" >&2
  exit 2
fi

queryEncoded=$(echo "$query" | sed "s| |+|g") # todo: more encode

log "Loading suggestions for '$query'..."

suggestions=$(curl "$BASE/start/searchSuggest.form?query=$queryEncoded")
suggestionsJSON=$(node -e 'JSON.stringify('"$suggestions"')' -p)

log "Filtering by tiptoi support..."



href=""

log "Getting gme url..."
productId=$(echo "$href" | grep -o "[-][0-9]*/index.html" | grep -o "[0-9]*")
gme=$(curl -s "$BASE/TiptoiDownload.form?itemId=$productId" | grep -o "https.*gme" | uniq)
log "Downloading gme..."
