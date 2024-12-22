#!/bin/bash

set -ex
base=$(
    cd $(dirname $0)
    pwd
)

set -a
source $base/.env
set +a

tf_path=/app/scripts/deploy/terraform/$RESOURCE_DIR

docker compose -f $base/terraform/docker-compose.yml up -d
docker exec terraform ls
docker exec terraform printenv
docker exec terraform apk update
docker exec terraform apk add jq
docker exec terraform sh -c "cd $tf_path && terraform init"
docker exec terraform sh -c "cd $tf_path && terraform refresh"
docker exec terraform sh -c "cd $tf_path && terraform plan"
docker exec terraform sh -c "cd $tf_path && terraform apply -auto-approve"
docker compose -f $base/terraform/docker-compose.yml down
