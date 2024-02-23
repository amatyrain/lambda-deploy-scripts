#!/bin/bash

set -e

echo "処理を続行しますか？"
read -p "y/n: " yn
case "$yn" in
  [yY]*) ;;
  *) echo "処理を中断しました" && exit 1 ;;
esac
