#!/bin/bash
# 研修PCクリーンアップ（WSL側）
# 実行: bash cleanup.sh          … クリーンアップ（削除）を行い、完了後に確認（--check 相当）も自動実行する
# 確認: bash cleanup.sh --check  … 個人データが消えたか＋開発環境が残っているかを確認する（read-only。何度でも安全に実行可）

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ホーム（~）直下で「消さずに残す」非隠し項目（このクリーンアップ用スクリプト自身）。
# 研修資料は ~/ 直下にバラけてコピーされるため、これ以外の非隠し項目はまとめて削除する。
KEEP_ITEMS="setup.sh cleanup.sh"

# ホーム（~）直下の「標準」隠し項目（開発環境の正規 dotfile／専用手順で消す認証系）。
# これ以外の隠し項目は「見慣れない隠し項目」として一覧表示だけする（自動削除はしない。
# 正規の dotfile を誤って消すと環境が壊れるため、削除は目視判断のうえ手動で行う）。
KNOWN_DOTFILES=".bashrc .bash_logout .bash_profile .profile .bash_history .config .cache
.local .vscode .vscode-server .vscode-remote-containers .gitconfig .claude .claude.json
.claude.json.backup .ssh .npm .java .m2 .mvn .dotnet .sdkman .gradle .gnupg .docker
.sts4 .wget-hsts .lesshst .sudo_as_admin_successful .motd_shown .landscape
.python_history .viminfo .netrc"

# $1 が $2 以降のリスト（空白区切り。要素に空白は含まない前提）に完全一致で含まれるか。
# 含まれれば 0、含まれなければ 1 を返す。
in_list() {
  local needle="$1"; shift
  local x
  for x in $@; do [ "$x" = "$needle" ] && return 0; done
  return 1
}

# ホーム（~）直下の隠し項目のうち、KNOWN_DOTFILES に無いものを配列 EXTRA_HIDDEN に格納する。
list_extra_hidden() {
  EXTRA_HIDDEN=()
  local item name
  shopt -s nullglob dotglob
  local items=("$HOME"/.*)
  shopt -u nullglob dotglob
  for item in "${items[@]}"; do
    name="$(basename "$item")"
    { [ "$name" = "." ] || [ "$name" = ".." ]; } && continue
    in_list "$name" $KNOWN_DOTFILES && continue
    EXTRA_HIDDEN+=("$name")
  done
}

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
  # mode="after-cleanup" のとき、研修資料のホーム一覧は再表示しない
  # （直前のクリーンアップ手順で同じ一覧を表示済みのため）
  local mode="$1"
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

  # 研修資料の確認（read-only。一覧を目視で確認する。対話入力はしない）
  echo ""
  if [ "$mode" = "after-cleanup" ]; then
    # クリーンアップ直後は削除手順で同じ一覧を表示済みのため、再表示しない
    echo -e "${GREEN}[--]${NC} 研修資料: クリーンアップ手順で削除（上の一覧に残っていなければ完了）"
  else
    # 研修資料は ~/ 直下にファイル・フォルダがバラけてコピーされる場合があるため、
    # 隠しファイルを除く全項目を表示する（$KEEP_ITEMS は残す想定なので除外して表示）
    echo "現在ホーム（~）にある研修資料の可能性がある項目（隠しファイル・$KEEP_ITEMS を除く）:"
    shopt -s nullglob
    HOME_ITEMS=("$HOME"/*)
    shopt -u nullglob
    _shown=0
    for item in "${HOME_ITEMS[@]}"; do
      name="$(basename "$item")"
      in_list "$name" $KEEP_ITEMS && continue
      if [ -d "$item" ]; then echo "  - $name/"; else echo "  - $name"; fi
      _shown=1
    done
    [ "$_shown" -eq 0 ] && echo "  （ありません）"
    echo -e "${GREEN}[--]${NC} 研修資料: 上記一覧に研修資料が無ければ削除済み"

    # 見慣れない隠し項目（標準 dotfile 以外）を参考表示する（自動削除はしない）
    echo ""
    list_extra_hidden
    if [ ${#EXTRA_HIDDEN[@]} -eq 0 ]; then
      echo -e "${GREEN}[--]${NC} 隠し項目: 標準以外の隠し項目はありません"
    else
      echo -e "${GREEN}[--]${NC} 見慣れない隠し項目（研修生が作成した可能性。中身を確認し不要なら手動削除）:"
      for name in "${EXTRA_HIDDEN[@]}"; do echo "    - $name"; done
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
  # 研修資料は ~/ 直下に複数のファイル・フォルダとしてバラけてコピーされるため、
  # $KEEP_ITEMS（setup.sh・cleanup.sh）以外の非隠し項目を一覧表示 → まとめて削除する。
  echo ""
  CURRENT_STEP="研修資料の削除"
  echo "=== $CURRENT_STEP ==="
  echo "ホーム（~）直下の非隠し項目のうち、$KEEP_ITEMS 以外をまとめて削除します。"

  shopt -s nullglob
  HOME_ITEMS=("$HOME"/*)
  shopt -u nullglob
  DEL_ITEMS=()
  for item in "${HOME_ITEMS[@]}"; do
    name="$(basename "$item")"
    in_list "$name" $KEEP_ITEMS && continue
    DEL_ITEMS+=("$item")
  done

  if [ ${#DEL_ITEMS[@]} -eq 0 ]; then
    echo "→ 削除対象（研修資料）はありません。"
  else
    echo ""
    echo "以下の ${#DEL_ITEMS[@]} 項目を削除します（$KEEP_ITEMS は残します）:"
    for item in "${DEL_ITEMS[@]}"; do
      if [ -d "$item" ]; then echo "  - $(basename "$item")/"; else echo "  - $(basename "$item")"; fi
    done
    echo ""
    read -p "これらをすべて削除しますか？ [y/N]: " DEL_CONFIRM
    if [ "$DEL_CONFIRM" = "y" ] || [ "$DEL_CONFIRM" = "Y" ]; then
      for item in "${DEL_ITEMS[@]}"; do
        rm -rf "$item"
        echo "  削除しました: $(basename "$item")"
      done
    else
      echo "→ 削除をスキップしました。"
    fi
  fi

  # 5b. 見慣れない隠し項目の参考表示（自動削除はしない。目視で判断して手動削除する）
  #     ホーム直下の dotfile は大半が開発環境の正規ファイルのため、スクリプトでは消さない。
  echo ""
  echo "--- 参考: 見慣れない隠し項目（自動削除はしません）---"
  list_extra_hidden
  if [ ${#EXTRA_HIDDEN[@]} -eq 0 ]; then
    echo "  標準以外の隠し項目は見つかりませんでした。"
  else
    echo "  標準の開発環境ファイル以外の隠し項目です。研修生が作成した不要物なら、中身を確認のうえ手動で削除してください（例: rm -rf ~/名前）:"
    for name in "${EXTRA_HIDDEN[@]}"; do echo "    - $name"; done
  fi

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
  echo "続けて確認を行います。"
  echo ""
  run_check after-cleanup
  echo ""
  echo "※ bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。"
  echo "※ 続けて Windows 側のクリーンアップ（cleanup.ps1）を実施してください。"
fi
