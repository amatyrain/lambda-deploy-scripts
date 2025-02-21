#!/bin/bash

base=$(cd $(dirname $0) && pwd)

# Load environment variables
[ -f "$base/.env" ] && source "$base/.env"

# Initialize with empty JSON if neither file exists
if [ ! -f "$base/.env" ] && [ ! -f "$base/$SECRET_PATH" ]; then
    echo "{}"
    exit 1
fi

# Process both files and merge results
(
    # Process .env file if it exists
    [ -f "$base/.env" ] && grep -v '^#' "$base/.env" | grep -v '^$'
    # Process SECRET_PATH file if it exists
    [ -f "$base/$SECRET_PATH" ] && grep -v '^#' "$base/$SECRET_PATH" | grep -v '^$'
) | sed 's/^/"/;s/=/": "/;s/$/"/' | sed '1s/^/{/;$!s/$/,/;$s/$/}/' | jq '.'
