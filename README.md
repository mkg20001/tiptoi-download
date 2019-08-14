# tiptoi-download

Simple script to download files onto your Tiptoi(r) device

# Usage

download: Run the script with a product id and a download folder. It will download the tiptoi file into that directory.

```
$ tiptoi-download download 55451 /tmp
```

list: Will output a JSON list of all tiptois

```
$ tiptoi-download list
```

search: Will search for a product and output suggestions as JSON

```
$ tiptoi-download search schatzsuche
```
