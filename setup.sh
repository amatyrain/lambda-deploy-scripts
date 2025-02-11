#!/bin/bash

# Create necessary directories
mkdir -p scripts/deploy/terraform/iam

# Navigate to terraform directory
cd scripts/deploy/terraform/iam || exit

# Run terraform commands
terraform init
terraform plan
terraform apply
