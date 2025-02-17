#!/bin/bash

# カレントディレクトリのパスを取得
base=$(cd $(dirname $0) && pwd)

# 環境変数ファイルの読み込み
if [ -f "$base/.env" ]; then
    source "$base/.env"
fi

# 環境変数ファイルが存在しない場合は空のJSONを返す
if [ ! -f "$base/$SECRET_PATH" ]; then
    echo "{}"
    exit 0
fi

# 一時ファイルを作成
tmpfile=$(mktemp)

# JSONの作成
{
    echo "{"
    first=true
    while IFS='=' read -r key value; do
        # 空行やコメントをスキップ
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        # クォートを削除
        value=$(echo "$value" | sed -e 's/^["\x27]//' -e 's/["\x27]$//')
        if [ "$first" = true ]; then
            first=false
        else
            echo -n ","
        fi
        printf '\n    "%s": "%s"' "$key" "$value"
    done < "$base/$SECRET_PATH"
    echo -e "\n}"
} > "$tmpfile"

# 整形されたJSONを出力
cat "$tmpfile" | jq '.'

# 一時ファイルを削除
rm -f "$tmpfile"
