#!/bin/bash

# プロジェクトルートに移動
cd /Users/consel/Sources/Github/schedule-deliver || exit

# Terraformディレクトリに移動
cd scripts/deploy/terraform/iam || exit

# 不要なポリシーファイルを削除
rm -f ../modules/iam/terraform-additional-policy.tf

# Terraform実行
terraform init
terraform plan
terraform apply -auto-approve
