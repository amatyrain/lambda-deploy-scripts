#!/bin/bash

set -ex
base=$(cd $(dirname $0); pwd;)


docker-compose -f $base/docker-compose.yml run --rm --entrypoint "sh" terraform -c \
    " \
    apk update \
    && apk add jq \
    && cd scripts/deploy/terraform/lambda/affiliate-bot \
    && terraform init \
    && terraform plan \
    && terraform apply -auto-approve \
    "
