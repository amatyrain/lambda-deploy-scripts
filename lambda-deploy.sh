#!/bin/bash

set -e
base=$(cd $(dirname $0); pwd;)

# 環境変数の読み込み
source $base/.env

HOME_DIR=$base/../..
DATA_DIR=$HOME_DIR/local/data
SRC_DIR=$HOME_DIR/src
SCRIPTS_DIR=$HOME_DIR/scripts
DEVELOP_DIR=$SCRIPTS_DIR/develop
ZIP_DIR=$DATA_DIR/zip
DEPLOY_DIR=$DATA_DIR/deploy
PYTHON_DIR=$DATA_DIR/python
MEMORY_SIZE=512
TIMEOUT=300

function initialize() {
    if [ "${LAMBDA_FUNCTION_NAME}" == "" ]; then
        echo "LAMBDA_FUNCTION_NAME is not set"
        exit 1
    fi

    # remove all files in deploy directory except .gitkeep
    if [ -e $DATA_DIR ]; then
        rm -rf $DATA_DIR/*
        touch $DATA_DIR/.gitkeep
    else
        mkdir $DATA_DIR
        touch $DATA_DIR/.gitkeep
    fi

    # if not exists deploy directory, create it
    mkdir $ZIP_DIR
    mkdir $DEPLOY_DIR
    mkdir $PYTHON_DIR
}

function create_lambda_layer_zip() {
    WORK_DIR=$(realpath $HOME_DIR)
    # cp $HOME_DIR/bin/chromedriver.zip data/python
    # cp $HOME_DIR/bin/headless-chromium.zip data/python
    docker run --rm -v $WORK_DIR:/var/task amazon/aws-sam-cli-build-image-python3.9:latest \
        bash -c "\
        pip install -r scripts/develop/requirements/prod.txt -t local/data/python && \
        (cd /var/task/local/data; zip -r zip/python.zip python)"
    # docker run --rm -v $WORK_DIR:/var/task amaffiscripts:latest \
    #     bash -c "\
    #     pip install --upgrade pip &&\
    #     pip install -r /var/task/scripts/develop/requirements/prod.txt -t /var/task/local/data/python &&\
    #     (cd /var/task/local/data; zip -r zip/python.zip python)"
}

function create_lambda_zip() {
    cp -r $SRC_DIR/* $DEPLOY_DIR
    (cd $DEPLOY_DIR; zip -r $ZIP_DIR/lambda_function.zip .)
}

function create_lambda_function() {
    aws lambda create-function \
    --function-name ${LAMBDA_FUNCTION_NAME} \
    --runtime ${RUNTIME} \
    --role ${CREATE_LAMBDA_ROLE_ARN} \
    --handler app.lambda_handler \
    --zip-file fileb://$ZIP_DIR/lambda_function.zip
}

function update_lambda_function() {
    # Lambda関数の更新
    aws lambda update-function-code \
        --function-name ${LAMBDA_FUNCTION_NAME} \
        --zip-file fileb://$ZIP_DIR/lambda_function.zip

    aws lambda update-function-configuration \
        --function-name ${LAMBDA_FUNCTION_NAME} \
        --memory-size ${MEMORY_SIZE} \
        --timeout ${TIMEOUT}

    # レイヤーが指定されている場合のみレイヤーを紐づける
    if [ "${LAMBDA_LAYER_ARN}" != "" ]; then
        # Lambda関数のレイヤーの更新
        latest_layer_version=$( \
            aws lambda list-layer-versions \
                --layer-name "${LAMBDA_LAYER_ARN}" \
                --query 'LayerVersions[0].Version' --output text \
        )

        aws lambda update-function-configuration \
            --function-name ${LAMBDA_FUNCTION_NAME} \
            --layers ${LAMBDA_LAYER_ARN}:$latest_layer_version
    fi

    # lambda_function_arn, event_target_id, event_rule_nameが空でない場合のみEventBridgeルールとLambda関数の関連付け
    if [ "${LAMBDA_FUNCTION_ARN}" != "" ] && [ "${LAMBDA_FUNCTION_NAME}" != "" ] && [ "${EVENT_RULE_NAME}" != "" ]; then
        # EventBridgeルールとLambda関数の関連付け
        aws events put-targets \
            --rule ${EVENT_RULE_NAME} \
            --targets Id=${LAMBDA_FUNCTION_NAME},Arn=${LAMBDA_FUNCTION_ARN}
    fi
}

# function create_lambda_layer() {
#     aws lambda publish-layer-version \
#         --layer-name ${LAMBDA_LAYER_NAME} \
#         --description "lambda layer for moneyforward-2" \
#         --license-info "MIT" \
#         --zip-file fileb://$DATA_DIR/lambda_layer.zip
# }
