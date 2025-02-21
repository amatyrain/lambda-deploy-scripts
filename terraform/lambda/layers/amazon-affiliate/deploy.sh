#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build the layer first
./build_layer.sh

# Initialize terraform if needed
terraform init

# Apply terraform configuration
terraform apply -auto-approve

echo "Lambda layer has been deployed successfully"
