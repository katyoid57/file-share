#!/bin/bash
set -e

RED='\033[0;31m'
NC='\033[0m'

CURRENT_STEP=""
trap 'echo -e "${RED}[ERROR]${NC} ${CURRENT_STEP} で失敗しました（line $LINENO）。"; exit 1' ERR

# 1. Claude Code 認証解除
CURRENT_STEP="Claude Code 認証解除"
echo "=== $CURRENT_STEP ==="
if [ ! -f "$HOME/.claude/.credentials.json" ]; then
  echo "→ 認証情報が無いためスキップします（既にログアウト済み）。"
elif command -v claude > /dev/null 2>&1; then
  claude logout || echo "→ logout に失敗しましたが続行します。"
else
  echo "→ Claude CLI が見つからないためスキップします。"
fi

# 2. GitHub CLI 認証解除（下流工程研修のみ）
echo ""
CURRENT_STEP="GitHub CLI 認証解除（下流工程研修のみ）"
echo "=== $CURRENT_STEP ==="
if command -v gh > /dev/null 2>&1 && gh auth status > /dev/null 2>&1; then
  gh auth logout
else
  echo "→ GitHub CLI が未認証のためスキップします（上流工程研修ではログインしていません）。"
fi

# 3. Claude Code の会話・プロジェクト履歴削除
echo ""
CURRENT_STEP="Claude Code 履歴削除"
echo "=== $CURRENT_STEP ==="
rm -rf "$HOME/.claude"
rm -f "$HOME/.claude.json" "$HOME/.claude.json.backup"
echo "削除しました: ~/.claude, ~/.claude.json"

# 4. git / bash の個人痕跡削除
echo ""
CURRENT_STEP="git / bash の個人痕跡削除"
echo "=== $CURRENT_STEP ==="
rm -f "$HOME/.gitconfig"
: > "$HOME/.bash_history" 2>/dev/null || true
history -c 2>/dev/null || true
echo "削除しました: ~/.gitconfig（~/.bash_history はクリア）"

# 5. 研修資料フォルダの削除
echo ""
CURRENT_STEP="研修資料フォルダの削除"
echo "=== $CURRENT_STEP ==="
echo "現在ホーム（~）にあるフォルダ:"
if ls -d "$HOME"/*/ > /dev/null 2>&1; then
  for d in "$HOME"/*/; do echo "  - $(basename "$d")"; done
else
  echo "  （フォルダはありません）"
fi
echo ""
read -p "削除する研修フォルダ名を入力してください（既に削除済み/不要なら空欄のまま Enter でスキップ）: " FOLDER_NAME

if [ -z "$FOLDER_NAME" ]; then
  echo "→ 入力が無いためスキップします（研修フォルダの削除は行いません）。"
else
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
    echo "フォルダが見つかりません（既に削除済みの可能性）: $TARGET"
  fi
fi

echo ""
echo "=== WSL側のクリーンアップ完了 ==="
echo "※ bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。"
echo "※ 続けて Windows 側のクリーンアップ（cleanup.ps1）を実施してください。"
