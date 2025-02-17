#!/bin/bash

base=$(cd $(dirname $0) && pwd)

# Load environment variables
[ -f "$base/.env" ] && source "$base/.env"

# Exit with error if secret file doesn't exist
[ ! -f "$base/$SECRET_PATH" ] && echo "{}" && exit 1

# Convert env file to JSON directly using jq
grep -v '^#' "$base/$SECRET_PATH" | grep -v '^$' | sed 's/^/"/;s/=/": "/;s/$/"/' | sed '1s/^/{/;$!s/$/,/;$s/$/}/' | jq '.'
