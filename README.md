# tiptoi-download

Simple script to download files onto your Tiptoi(r) device

## Dependencies

- nodejs
- jq
- curl

## Usage

Interactive:

Run the script. It will first ask which tiptoi to use, then enter a search query and select the right result. It will then get downloaded.

```console
$ tiptoi-download
[0] Tiptoi  ZC3203L
Search query: schatzsuche
1565794684: Loading suggestions for 'schatzsuche'...
[0] tiptoi® CREATE Schatzsuche im Dschungel
[1] tiptoi® Schatzsuche in der Buchstabenburg
> 1
```

download: Run the script with a product id and a download folder. It will download the tiptoi file into that directory.

```
$ tiptoi-download download 55415 /tmp
```

list: Will output a JSON list of all tiptois

```
$ tiptoi-download list
```

search: Will search for a product and output suggestions as JSON

```
$ tiptoi-download search schatzsuche
```
