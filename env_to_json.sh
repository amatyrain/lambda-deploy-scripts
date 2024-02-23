#!/bin/bash

# .envファイルから環境変数を読み込む
set -a
base=$(cd $(dirname $0); pwd)

source $base/.env
secret_env=$(realpath "$base/$SECRET_PATH")

set +a

# 環境変数をJSONに変換
cat $secret_env | \
    grep -v "=$" | \
    # grep -v "AWS_ACCESS_KEY_ID" | \
    # grep -v "AWS_SECRET_ACCESS_KEY" | \
    grep "=" | \
    jq -nR 'reduce inputs as $line ({}; . + { ($line | split("=")[0]): ($line | split("=")[1:]) | join("=") })'
