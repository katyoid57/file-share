#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== クリーンアップ確認（WSL側）==="
echo ""

# Claude Code 認証・履歴の確認
if [ -e "$HOME/.claude/.credentials.json" ]; then
  echo -e "${RED}[NG]${NC} Claude Code: 認証情報が残っています（~/.claude/.credentials.json）"
elif [ -d "$HOME/.claude" ] || [ -f "$HOME/.claude.json" ]; then
  echo -e "${RED}[NG]${NC} Claude Code: 履歴/設定が残っています（~/.claude, ~/.claude.json）"
else
  echo -e "${GREEN}[OK]${NC} Claude Code: 認証解除・履歴削除済み"
fi

# GitHub CLI 認証状態の確認（下流工程研修のみ）
if gh auth status > /dev/null 2>&1; then
  echo -e "${RED}[NG]${NC} GitHub CLI（下流工程研修のみ）: 認証情報が残っています"
else
  echo -e "${GREEN}[OK]${NC} GitHub CLI（下流工程研修のみ）: 認証解除済み（または未使用）"
fi

# git 設定の確認
if [ -f "$HOME/.gitconfig" ]; then
  echo -e "${RED}[NG]${NC} git 設定: ~/.gitconfig が残っています"
else
  echo -e "${GREEN}[OK]${NC} git 設定: ~/.gitconfig 削除済み"
fi

# 研修資料フォルダの確認
echo ""
# 研修資料は ~/ 直下にファイル・フォルダがバラけてコピーされる場合があるため、
# フォルダだけでなく隠しファイルを除く全項目を表示する
echo "現在ホーム（~）にあるファイル・フォルダ（隠しファイルを除く）:"
shopt -s nullglob
HOME_ITEMS=("$HOME"/*)
shopt -u nullglob
if [ ${#HOME_ITEMS[@]} -gt 0 ]; then
  for item in "${HOME_ITEMS[@]}"; do
    if [ -d "$item" ]; then echo "  - $(basename "$item")/"; else echo "  - $(basename "$item")"; fi
  done
else
  echo "  （ありません）"
fi
echo ""
read -p "削除を確認したい研修資料の名前を入力してください（ファイル/フォルダ可。不明/不要なら空欄のまま Enter でスキップ）: " FOLDER_NAME

if [ -z "$FOLDER_NAME" ]; then
  echo -e "${GREEN}[--]${NC} 研修資料: 確認をスキップしました（上記一覧に研修資料が無ければ削除済み）"
else
  TARGET="$HOME/$FOLDER_NAME"
  if [ -e "$TARGET" ]; then
    echo -e "${RED}[NG]${NC} 研修資料: $TARGET が残っています"
  else
    echo -e "${GREEN}[OK]${NC} 研修資料: $TARGET は削除済み"
  fi
fi

echo ""
echo "=== 確認完了 ==="
