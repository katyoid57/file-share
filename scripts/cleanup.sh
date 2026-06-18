#!/bin/bash
# 研修PCクリーンアップ（WSL側）
# 実行: bash cleanup.sh          … クリーンアップ（削除）を行い、完了後に確認（--check 相当）も自動実行する
# 確認: bash cleanup.sh --check  … 個人データが消えたか＋開発環境が残っているかを確認する（read-only。何度でも安全に実行可）

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 標準セット外の VSCode 拡張を検出し、グローバル配列 EXTRA に格納する。
# セットアップでインストールする標準拡張の発行元（publisher）で判定する。
# 拡張パック（Java/Spring）は子拡張を多数導入するため、ID 個別ではなく発行元で判定する。
#   ms-vscode-remote … WSL ／ vscjava・redhat・vmware・VisualStudioExptTeam … Java/Spring Boot 拡張パックと依存
#   cweijan … Office Viewer（上流工程研修のみ）
# 戻り値: 0=code あり（EXTRA に結果格納） / 1=code が無い（検出不可）
detect_extra_extensions() {
  EXTRA=()
  command -v code > /dev/null 2>&1 || return 1
  local KNOWN_PUBLISHERS="ms-vscode-remote vscjava redhat vmware VisualStudioExptTeam cweijan"
  local ext pub
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    # 拡張機能ID（publisher.name）形式でない行は無視する（環境によっては code が見出し行等を出すため）
    [[ "$ext" =~ ^[^[:space:]]+\.[^[:space:]]+$ ]] || continue
    pub="${ext%%.*}"
    if ! echo " $KNOWN_PUBLISHERS " | grep -qi " $pub "; then
      EXTRA+=("$ext")
    fi
  done < <(code --list-extensions 2>/dev/null)
  return 0
}

# ===== 確認モード（--check）: 「次の研修生に渡せる状態か」を確認する（read-only）=====
run_check() {
  check_command() {
    local name=$1
    local cmd=$2
    if eval "$cmd" > /dev/null 2>&1; then
      local version=$(eval "$cmd" 2>&1 | head -n 1)
      echo -e "${GREEN}[OK]${NC} $name: $version"
    else
      echo -e "${RED}[NG]${NC} $name: コマンドが見つからないか実行できません"
    fi
  }

  echo "=== クリーンアップ確認（WSL側）==="
  echo ""
  echo "【1】個人データが消えているか"

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

  # 研修資料の確認
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
      echo -e "${GREEN}[OK]${NC} 研修資料: $TARGET は存在しません"
    fi
  fi

  # VSCode 拡張機能の確認（研修生が追加した標準セット外の拡張を検出。read-only。削除はしない）
  echo ""
  if detect_extra_extensions; then
    if [ ${#EXTRA[@]} -eq 0 ]; then
      echo -e "${GREEN}[OK]${NC} VSCode 拡張機能: 標準セット以外の拡張は見つかりませんでした"
    else
      echo -e "${RED}[NG]${NC} VSCode 拡張機能: 標準セット以外の拡張が ${#EXTRA[@]} 件あります（研修生が追加した可能性）"
      for e in "${EXTRA[@]}"; do echo "    - $e"; done
      echo "    → クリーンアップ実行（bash cleanup.sh）で一覧表示し、確認のうえまとめて削除できます"
    fi
  else
    echo -e "${GREEN}[--]${NC} VSCode 拡張機能: code コマンドが見つかりません（VSCode の WSL ターミナルで実行してください）"
  fi

  # 開発環境（ツール）が残っているか＝セットアップ完了状態に戻っているか
  echo ""
  echo "【2】開発環境が残っているか（ツールは消さずに残す）"
  check_command "GitHub CLI"      "gh --version"
  check_command "Claude CLI"      "claude --version"
  check_command "GitHub Copilot"  "gh copilot --version"
  check_command "JDK"             "java -version"
  check_command "Maven"           "mvn -version"
  echo "JAVA_HOME: ${JAVA_HOME:-(未設定)}"
  echo "M2_HOME:   ${M2_HOME:-(未設定)}"

  echo ""
  echo "=== 確認完了 ==="
  echo "※ 【1】がすべて [OK]／[--]、【2】がすべて [OK] であれば、次の研修生に渡せる状態（セットアップ完了状態）です。"
}

# ===== 実行モード: クリーンアップ（削除）を行う =====
run_cleanup() {
  set -e

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
  echo "※ サーバー側セッションは手順1のブラウザ手動ログアウトで無効化されます。"

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
  if [ -e "$HOME/.claude" ] || [ -f "$HOME/.claude.json" ] || [ -f "$HOME/.claude.json.backup" ]; then
    rm -rf "$HOME/.claude"
    rm -f "$HOME/.claude.json" "$HOME/.claude.json.backup"
    echo "削除しました: ~/.claude, ~/.claude.json"
  else
    echo "→ 履歴/設定が無いためスキップします（既に削除済み）。"
  fi

  # 4. git / bash の個人痕跡削除
  echo ""
  CURRENT_STEP="git / bash の個人痕跡削除"
  echo "=== $CURRENT_STEP ==="
  if [ -f "$HOME/.gitconfig" ]; then
    rm -f "$HOME/.gitconfig"
    echo "削除しました: ~/.gitconfig"
  else
    echo "→ ~/.gitconfig が無いためスキップします（既に削除済み）。"
  fi
  : > "$HOME/.bash_history" 2>/dev/null || true
  history -c 2>/dev/null || true
  echo "bash 履歴をクリアしました（~/.bash_history）。"

  # 5. 研修資料の削除
  # 研修資料は ~/ 直下に複数のファイル・フォルダとしてバラけてコピーされる場合があるため、
  # 一覧表示 → 入力 → 削除 を繰り返し、空欄 Enter で終了する
  echo ""
  CURRENT_STEP="研修資料の削除"
  echo "=== $CURRENT_STEP ==="
  echo "（研修資料が複数のファイル・フォルダに分かれている場合は、続けて入力できます）"
  while true; do
    echo ""
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
    read -p "削除する研修資料の名前を入力してください（ファイル/フォルダ可。終了/不要なら空欄のまま Enter）: " FOLDER_NAME

    if [ -z "$FOLDER_NAME" ]; then
      echo "→ 研修資料の削除を終了します。"
      break
    fi

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
  done

  # 6. VSCode 標準セット外拡張の削除（研修生が追加した拡張。発行元で判定し、一覧→確認→ループ削除）
  echo ""
  CURRENT_STEP="VSCode 標準外拡張の削除"
  echo "=== $CURRENT_STEP ==="
  if detect_extra_extensions; then
    if [ ${#EXTRA[@]} -eq 0 ]; then
      echo "→ 標準セット以外の拡張は見つかりませんでした。"
    else
      echo "標準セット以外の拡張が ${#EXTRA[@]} 件あります（研修生が追加した可能性）:"
      for e in "${EXTRA[@]}"; do echo "  - $e"; done
      read -p "これらをまとめてアンインストールしますか？ [y/N]: " EXT_CONFIRM
      if [ "$EXT_CONFIRM" = "y" ] || [ "$EXT_CONFIRM" = "Y" ]; then
        for e in "${EXTRA[@]}"; do
          if code --uninstall-extension "$e" > /dev/null 2>&1; then
            echo "  削除しました: $e"
          else
            echo "  削除に失敗（手動で確認してください）: $e"
          fi
        done
      else
        echo "→ 削除をスキップしました。"
      fi
    fi
  else
    echo "→ code コマンドが無いためスキップします（VSCode の WSL ターミナルで実行してください）。"
  fi

  echo ""
  echo "=== WSL側のクリーンアップ完了 ==="
}

# ===== エントリポイント =====
if [ "$1" = "--check" ]; then
  run_check
else
  echo "これは「クリーンアップ実行」です（削除を行います）。確認だけなら: bash cleanup.sh --check"
  read -p "クリーンアップを実行しますか？ [y/N]: " ANS
  if [ "$ANS" != "y" ] && [ "$ANS" != "Y" ]; then
    echo "中止しました。確認のみは bash cleanup.sh --check で実行できます。"
    exit 0
  fi
  run_cleanup

  # 削除に続けて確認（--check 相当）を自動実行する（read-only）。
  # run_cleanup の set -e / ERR トラップを解除してから回す（確認内の非ゼロ終了で止めないため）。
  set +e
  trap - ERR
  echo ""
  echo "続けて確認を行います（bash cleanup.sh --check と同じ内容）。"
  echo ""
  run_check
  echo ""
  echo "※ bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。"
  echo "※ 続けて Windows 側のクリーンアップ（cleanup.ps1）を実施してください。"
fi
