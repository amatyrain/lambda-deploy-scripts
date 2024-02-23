#!/bin/bash

set -e
base=$(cd $(dirname $0); pwd)

echo "リモートのシークレット一覧"
gh secret list

echo "ローカルのシークレット一覧"
cat $base/.env
source $base/.env

if [ "$SECRET_PATH" != "" ]; then
  secret_env=$(realpath "$base/$SECRET_PATH")
  cat $secret_env
fi


echo "上記の内容でリモートのシークレットを更新しますか？"
read -p "y/n: " yn
case "$yn" in
  [yY]*) ;;
  *) echo "処理を中断しました" && exit 1 ;;
esac

gh secret set -f $base/.env
if [ "$SECRET_PATH" != "" ]; then
  gh secret set -f $secret_env
fi
gh secret list
