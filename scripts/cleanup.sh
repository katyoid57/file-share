#!/bin/bash
set -e

RED='\033[0;31m'
NC='\033[0m'

CURRENT_STEP=""
trap 'echo -e "${RED}[ERROR]${NC} ${CURRENT_STEP} で失敗しました（line $LINENO）。"; exit 1' ERR

CURRENT_STEP="Claude Code 認証解除"
echo "=== $CURRENT_STEP ==="
claude logout

CURRENT_STEP="GitHub CLI 認証解除"
echo "=== $CURRENT_STEP ==="
gh auth logout

CURRENT_STEP="研修資料フォルダの削除"
echo "=== $CURRENT_STEP ==="
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
