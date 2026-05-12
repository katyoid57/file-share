#!/bin/bash
set -e

echo "=== Claude Code 認証解除 ==="
claude logout

echo "=== GitHub CLI 認証解除 ==="
gh auth logout

echo "=== 研修資料フォルダの削除 ==="
read -p "削除する研修フォルダ名を入力してください（例: training-2026）: " FOLDER_NAME
TARGET="$HOME/$FOLDER_NAME"

if [ -d "$TARGET" ]; then
  read -p "「$TARGET」を削除しますか？ [y/N]: " CONFIRM
  if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
    rm -rf "$TARGET"
    echo "削除しました: $TARGET"
  else
    echo "削除をスキップしました。"
  fi
else
  echo "フォルダが見つかりません: $TARGET"
fi

echo ""
echo "=== クリーンアップ完了 ==="
