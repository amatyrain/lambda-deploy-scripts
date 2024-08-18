#!/bin/bash

set -ex
base=$(cd $(dirname $0); pwd;)

docker compose -f $base/docker-compose.yml run --rm --entrypoint "sh" terraform -c \
    ' \
    printenv \
    && apk update \
    && apk add jq \
    && cd scripts/deploy/terraform/$RESOURCE_DIR \
    && terraform init \
    && terraform refresh \
    && terraform plan \
    && terraform apply -auto-approve \
    '
