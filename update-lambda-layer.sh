#!/bin/bash

set -ex
base=$(
    cd $(dirname $0)
    pwd
)

# 環境変数の読み込み
source $base/lambda-deploy.sh

create_lambda_layer_zip
create_lambda_layer
