#!/bin/bash

# Set working directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create package directory structure
mkdir -p package/python

# Install dependencies
pip install -r requirements/prod.txt --target package/python

# Remove unnecessary files
find package/python -type d -name "__pycache__" -exec rm -rf {} +
find package/python -type f -name "*.pyc" -delete
find package/python -type f -name "*.pyo" -delete
