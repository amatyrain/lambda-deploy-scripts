#!/bin/bash

cd "$(dirname "$0")"

# AWSの認証情報を設定
if [ -f "../../../../../.env" ]; then
    source "../../../../../.env"
fi

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

cd ../../

# terraform init の実行
docker compose run --rm --entrypoint="" terraform terraform -chdir=/app/scripts/deploy/terraform/lambda/mini-scripts2 init

# terraform plan の実行
docker compose run --rm --entrypoint="" terraform terraform -chdir=/app/scripts/deploy/terraform/lambda/mini-scripts2 plan

# terraform apply の実行
docker compose run --rm --entrypoint="" terraform terraform -chdir=/app/scripts/deploy/terraform/lambda/mini-scripts2 apply -auto-approve