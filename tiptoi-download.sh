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
    cmd_help

    err "No tiptois found"
    return 2

  fi

  jsonSelect "$tiptois" ".[] | (.vendor + .model)"

  MNT=$(echo "$item" | jq -r .mountpoint)
  if [ -z "$MNT" ] && [ "$MNT" != "null" ]; then
    MNT=$(mktemp -d)
    log "Mounting under $MNT..."
    sudo mount /dev/"$(echo "$item" | jq -r .name)" "$MNT"
  fi
}
cmd_help(){
  cat <<EOF
usage: tiptoi-download [COMMAND]

Interactive mode (no COMMAND given):
  It will first ask which tiptoi to use, then enter a search query and select the right result. It will then get downloaded.

    $ tiptoi-download
    [0] Tiptoi  ZC3203L
    Search query: schatzsuche
    1565794684: Loading suggestions for 'schatzsuche'...
    [0] tiptoi® CREATE Schatzsuche im Dschungel
    [1] tiptoi® Schatzsuche in der Buchstabenburg
    > 1

COMMAND can be one of:

  download TITLEID FOLDER:  Download a title to a given folder
    PRODUCTID:                the id of the Book you want to download
    FOLDER:                   the destination folder where to download

  list:                     output a JSON list of all tiptois

  search QUERY:             search for a product and output suggestions as JSON
    QUERY:                    Query String

  help:                     This help

EOF
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
