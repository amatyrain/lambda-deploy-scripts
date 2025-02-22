#!/bin/bash

CALLER_DIR="$(pwd)"

# Load environment variables
[ -f "$CALLER_DIR/.env" ] && source "$CALLER_DIR/.env"

# Initialize with empty JSON if neither file exists
if [ ! -f "$CALLER_DIR/.env" ] && [ ! -f "$CALLER_DIR/$SECRET_PATH" ]; then
    echo "{}"
    exit 1
fi

# Process both files and merge results
(
    # Process .env file if it exists
    [ -f "$CALLER_DIR/.env" ] && grep -v '^#' "$CALLER_DIR/.env" | grep -v '^$'
    # Process SECRET_PATH file if it exists
    [ -f "$CALLER_DIR/$SECRET_PATH" ] && grep -v '^#' "$CALLER_DIR/$SECRET_PATH" | grep -v '^$'
) | sed 's/^/"/;s/=/": "/;s/$/"/' | sed '1s/^/{/;$!s/$/,/;$s/$/}/' | jq '.'