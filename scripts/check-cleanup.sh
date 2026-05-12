#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== クリーンアップ確認 ==="
echo ""

# Claude Code 認証状態の確認
if [ -d "$HOME/.claude" ] && [ -f "$HOME/.claude/.credentials.json" ]; then
  echo -e "${RED}[NG]${NC} Claude Code: 認証情報が残っています（~/.claude/.credentials.json）"
else
  echo -e "${GREEN}[OK]${NC} Claude Code: 認証解除済み"
fi

# GitHub CLI 認証状態の確認
if gh auth status > /dev/null 2>&1; then
  echo -e "${RED}[NG]${NC} GitHub CLI: 認証情報が残っています"
else
  echo -e "${GREEN}[OK]${NC} GitHub CLI: 認証解除済み"
fi

# 研修資料フォルダの確認
echo ""
read -p "削除を確認したい研修フォルダ名を入力してください（例: training-2026）: " FOLDER_NAME
TARGET="$HOME/$FOLDER_NAME"

if [ -d "$TARGET" ]; then
  echo -e "${RED}[NG]${NC} 研修フォルダ: $TARGET が残っています"
else
  echo -e "${GREEN}[OK]${NC} 研修フォルダ: $TARGET は削除済み"
fi

echo ""
echo "=== 確認完了 ==="
