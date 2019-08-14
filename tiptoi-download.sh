#!/bin/bash

set -e

BASE="https://www.ravensburger.de"
TMP=$(mktemp)

log() {
  echo "$(date +%s): $*"
}

err() {
  echo "ERROR: $*" >&2
}

menu() {
  i=0
  list=()

  while [ ! -z "$1" ]; do
    list+=("$1")

    echo "[$i] $1"
    i=$((i+1))
    shift
  done

  if [[ "$i" == "1" ]]; then
    RES="0"
  else
    RES=""
  fi

  while [ -z "$RES" ]; do
    read -p "> " sel
    if [ ! -z "${list[$sel]}" ]; then
      RES="$sel"
    fi
  done
}

jsonSelect() {
  INPUT="$1"
  FILTER="$2"

  list=()
  echo "$INPUT" | jq -r "$FILTER" >"$TMP"
  while read input; do
    list+=("$input")
  done <"$TMP"

  menu "${list[@]}"
  item=$(echo "$INPUT" | jq ".[$RES]")
}

doSearch() {
  query="$*"

  if [ -z "$query" ]; then
    err "No search query supplied"
    return 2
  fi

  queryEncoded=$(echo "$query" | sed "s| |+|g") # todo: more encode

  suggestions=$(curl -s "$BASE/start/searchSuggest.form?query=$queryEncoded")
  suggestionsJSON=$(node -e 'JSON.stringify('"$suggestions"'.produkte.filter(produkt => produkt.label.startsWith("tiptoi")))' -p)
}

search() {
  log "Loading suggestions for '$*'..."

  doSearch "$@"
  
  if [[ "$suggestionsJSON" == "[]" ]]; then
    err "Nothing found for tiptoi"
    return 1
  fi

  jsonSelect "$suggestionsJSON" ".[] | .label"

  log "Downloading $(echo "$item" | jq -r ".label")..."

  download "$(echo "$item" | jq -r ".artikelNr")"
}

download() {
  productId="$1"

  if [ -z "$productId" ]; then
    err "No product id supplied!"
  fi

  gme=$(curl -s "$BASE/TiptoiDownload.form?itemId=$productId" | grep -o "https.*gme" | uniq)
  log "Downloading gme..."
  
  wget -O "$MNT/$(basename "$gme")" "$gme"
}

get_tiptois() {
  tiptois=$(lsblk -Jo name,rm,size,ro,type,mountpoint,hotplug,label,uuid,model,serial,rev,vendor,hctl | jq -c '.blockdevices[] | select(.vendor == "Tiptoi  ")' | jq -sc ".")
}

device() {
  get_tiptois
  
  if [[ "$tiptois" == "[]" ]]; then
    err "No tiptois found"
    return 2
  fi

  jsonSelect "$tiptois" ".[] | (.vendor + .model)"

  MNT=$(echo "$item" | jq -r .mountpoint)
  if [ -z "$MNT" ]; then
    MNT=$(mktemp -d)
    log "Mounting under $MNT..."
    sudo mount /dev/"$(echo "$item" | jq -r .name)" "$MNT"
  fi
}

cmd_list() {
  get_tiptois
  
  echo "$tiptois"
}

cmd_search() {
  doSearch "$@"

  echo "$suggestionsJSON"
}

cmd_download() {
  MNT="$2"
  download "$1"
}

if [ -z "$1" ]; then
  device

  while true; do
    read -p "Search query: " input
    if [ ! -z "$input" ]; then
      search "$input" || /bin/true
    fi
  done
else
  CMD="$1"
  shift
  "cmd_$CMD" "$@"
fi
