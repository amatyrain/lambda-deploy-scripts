#!/bin/bash
set -e

# プロジェクトルートからの相対パス
PROJECT_ROOT=$(dirname "$(dirname "$(dirname "$(dirname "$0")")")")

# ディレクトリ作成
mkdir -p "$PROJECT_ROOT/scripts/deploy/terraform/iam"
cd "$PROJECT_ROOT/scripts/deploy/terraform/iam"

# 既存のIAMポリシーを適用
terraform init
terraform apply -auto-approve

echo "✅ IAM setup completed"
