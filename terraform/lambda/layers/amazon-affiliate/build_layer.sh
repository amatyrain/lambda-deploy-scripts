#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Clean up existing files
rm -rf python layer.zip

# Build Docker image and create layer
docker build -t amazon-affiliate-layer .

# Get container ID from the image
CONTAINER_ID=$(docker create amazon-affiliate-layer)

# Copy layer.zip from container
docker cp "$CONTAINER_ID:/var/task/layer.zip" .

# Remove container
docker rm "$CONTAINER_ID"

echo "Layer has been built and saved as layer.zip"
