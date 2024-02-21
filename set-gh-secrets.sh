#!/bin/bash

set -e
base=$(cd $(dirname $0); pwd)

source $base/.env
secret_env=$(realpath "$base/$SECRET_PATH")

echo "リモートのシークレット一覧"
gh secret list

echo "ローカルのシークレット一覧"
cat $base/.env
cat $secret_env

echo "上記の内容でリモートのシークレットを更新しますか？"
read -p "y/n: " yn
case "$yn" in
  [yY]*) ;;
  *) echo "処理を中断しました" && exit 1 ;;
esac

gh secret set -f $base/.env
gh secret set -f $secret_env
gh secret list
