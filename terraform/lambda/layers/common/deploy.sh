#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALLER_DIR="$(pwd)"

# Generate env.json if needed
"$SCRIPT_DIR/env_to_json.sh" > "$CALLER_DIR/env.json" || true

# Build the layer
"$SCRIPT_DIR/build_layer.sh"

# Initialize terraform if needed
terraform init

# Show plan and ask for confirmation
terraform plan
echo
echo "Do you want to apply these changes? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    # Apply terraform configuration with auto-approve
    terraform apply -auto-approve

    echo "Lambda layer has been deployed successfully"
else
    echo "Deployment cancelled"
fi

# Cleanup
rm -f env.json