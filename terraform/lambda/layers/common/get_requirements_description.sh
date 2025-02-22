#!/bin/bash

set -eu

CALLER_DIR="$(pwd)"
LAYER_NAME="$(basename "$CALLER_DIR")"

# Combine requirements from common.txt and prod.txt, excluding comments, empty lines, and requirement file references
REQUIREMENTS=$(cat "$CALLER_DIR/requirements/common.txt" "$CALLER_DIR/requirements/prod.txt" 2>/dev/null | grep -v '^#' | grep -v '^-r' | grep -v '^$' | sort -u | tr '\n' ',' | sed 's/,$//')

echo "Layer containing ${LAYER_NAME} related libraries: ${REQUIREMENTS}"