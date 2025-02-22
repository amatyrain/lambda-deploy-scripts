#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALLER_DIR="$(pwd)"
LAYER_NAME="$(basename "$CALLER_DIR")"

# Generate description from requirements
"$SCRIPT_DIR/get_requirements_description.sh" > "$CALLER_DIR/.description"

# Clean up existing files
rm -rf python layer.zip

# Build Docker image and create layer
docker build -t "$LAYER_NAME-layer" -f "$SCRIPT_DIR/Dockerfile" .

# Get container ID from the image
CONTAINER_ID=$(docker create "$LAYER_NAME-layer")

# Copy layer.zip from container
docker cp "$CONTAINER_ID:/var/task/layer.zip" .

# Remove container
docker rm "$CONTAINER_ID"

echo "Layer has been built and saved as layer.zip"