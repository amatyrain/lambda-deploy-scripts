#!/bin/bash

# usage: RESOURCE_DIR=terraform/lambda/layers/amazon-affiliate ./terraform-deploy-auto.sh

set -ex
base=$(
    cd $(dirname $0)/../../../../../scripts/deploy
    pwd
)

set -a
source $base/.env
set +a

# パスを修正: /appのterraformディレクトリ下を参照するように変更
tf_path=/app/scripts/deploy/terraform/$RESOURCE_DIR

docker compose -f $base/terraform/docker-compose.yml up -d
docker exec terraform ls
docker exec terraform printenv
docker exec terraform apk update
docker exec terraform apk add jq
docker exec terraform sh -c "cd $tf_path && cp /app/scripts/deploy/env_to_json.sh . && terraform init"
docker exec terraform sh -c "cd $tf_path && terraform refresh"
docker exec terraform sh -c "cd $tf_path && terraform plan"
docker exec terraform sh -c "cd $tf_path && terraform apply -auto-approve"
docker compose -f $base/terraform/docker-compose.yml down
