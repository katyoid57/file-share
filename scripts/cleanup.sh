#!/bin/bash
set -e

RED='\033[0;31m'
NC='\033[0m'

CURRENT_STEP=""
trap 'echo -e "${RED}[ERROR]${NC} ${CURRENT_STEP} で失敗しました（line $LINENO）。"; exit 1' ERR

# 1. Claude Code 認証解除（認証情報ファイルを直接削除する。
#    claude logout は環境によって対話的なログイン画面を開くことがあるため呼ばない）
CURRENT_STEP="Claude Code 認証解除"
echo "=== $CURRENT_STEP ==="
if [ -f "$HOME/.claude/.credentials.json" ]; then
  rm -f "$HOME/.claude/.credentials.json"
  echo "認証情報を削除しました（~/.claude/.credentials.json）。"
else
  echo "→ 認証情報が無いためスキップします（既にログアウト済み）。"
fi
echo "※ サーバー側セッションは手順0のブラウザ手動ログアウトで無効化されます。"

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
read -p "削除する研修資料の名前を入力してください（ファイル/フォルダ可。既に削除済み/不要なら空欄のまま Enter でスキップ）: " FOLDER_NAME

if [ -z "$FOLDER_NAME" ]; then
  echo "→ 入力が無いためスキップします（研修資料の削除は行いません）。"
else
  TARGET="$HOME/$FOLDER_NAME"
  if [ -e "$TARGET" ]; then
    read -p "「$TARGET」を削除しますか？ [y/N]: " CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
      rm -rf "$TARGET"
      echo "削除しました: $TARGET"
    else
      echo "削除をスキップしました。"
    fi
  else
    echo "見つかりません（既に削除済みの可能性）: $TARGET"
  fi
fi

echo ""
echo "=== WSL側のクリーンアップ完了 ==="
echo "※ bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。"
echo "※ 続けて Windows 側のクリーンアップ（cleanup.ps1）を実施してください。"
