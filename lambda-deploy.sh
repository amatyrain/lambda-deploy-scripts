#!/bin/bash

set -e
base=$(
    cd $(dirname $0)
    pwd
)

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
MEMORY_SIZE=1024
TIMEOUT=600
DOCKER_COMPOSE_LAMBDA_LAYER=$base/docker-compose.lambda-layer.yml

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
    docker compose -f $DOCKER_COMPOSE_LAMBDA_LAYER up -d
    docker exec -it lambda-layer pip install --upgrade pip
    docker exec -it lambda-layer pip install -r scripts/develop/requirements/prod.txt -t local/data/python
    docker exec -it lambda-layer bash -c "mkdir -p /app/local/data/zip && cd /app/local/data && zip -r zip/python.zip python"
    docker compose -f $DOCKER_COMPOSE_LAMBDA_LAYER down

    # docker run --rm -v $WORK_DIR:/var/task amaffiscripts:latest \
    #     bash -c "\
    #     pip install --upgrade pip &&\
    #     pip install -r /var/task/scripts/develop/requirements/prod.txt -t /var/task/local/data/python &&\
    #     (cd /var/task/local/data; zip -r zip/python.zip python)"
}

function create_lambda_zip() {
    cp -r $SRC_DIR/* $DEPLOY_DIR
    (
        cd $DEPLOY_DIR
        zip -r $ZIP_DIR/lambda_function.zip .
    )
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

    # src/amaffiscripts/core/infrastructure/secret/.envの内容を環境変数として設定
    aws lambda update-function-configuration \
        --function-name ${LAMBDA_FUNCTION_NAME} \
        --memory-size ${MEMORY_SIZE} \
        --environment "Variables={$(cat $SECRET_DIR/.env | grep "=" | tr '\n' ',' | sed 's/,$//')}" \
        --timeout ${TIMEOUT}

    # レイヤーが指定されている場合のみレイヤーを紐づける
    if [ "${LAMBDA_LAYER_ARN}" != "" ]; then
        # Lambda関数のレイヤーの更新
        latest_layer_version=$(
            aws lambda list-layer-versions \
                --layer-name "${LAMBDA_LAYER_ARN}" \
                --query 'LayerVersions[0].Version' --output text
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

function create_lambda_layer() {
    aws lambda publish-layer-version \
        --layer-name "${LAMBDA_LAYER_NAME}" \
        --description "lambda layer" \
        --license-info "MIT" \
        --zip-file fileb://$DATA_DIR/zip/python.zip
}
