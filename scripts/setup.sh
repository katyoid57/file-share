#!/bin/bash
# 研修環境セットアップ（CLI・JDK・Maven）
# 実行: bash setup.sh          … インストールする
# 確認: bash setup.sh --check  … インストール状況を確認する（read-only。何度でも安全に実行可）

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ===== 確認モード（--check）: インストール状況を確認する（read-only）=====
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

  echo "=== インストール確認 ==="
  echo ""
  check_command "GitHub CLI"      "gh --version"
  check_command "Claude CLI"      "claude --version"
  check_command "GitHub Copilot"  "gh copilot --version"
  check_command "JDK"             "java -version"
  check_command "Maven"           "mvn -version"

  echo ""
  echo "=== 環境変数 ==="
  echo "JAVA_HOME: ${JAVA_HOME:-(未設定)}"
  echo "M2_HOME:   ${M2_HOME:-(未設定)}"

  echo ""
  echo "=== 確認完了 ==="
}

# ===== 実行モード: インストールする =====
run_setup() {
  set -e

  CURRENT_STEP=""
  trap 'echo -e "${RED}[ERROR]${NC} ${CURRENT_STEP} で失敗しました（line $LINENO）。もう一度 bash setup.sh を実行すると、成功済みのステップはスキップされます。"; exit 1' ERR

  # 同じ行が既に ~/.bashrc にある場合は追記しない
  append_bashrc_once() {
    local line=$1
    grep -qxF "$line" ~/.bashrc 2>/dev/null || echo "$line" >> ~/.bashrc
  }

  # 指定秒数だけカウントダウン表示しながら待機する（前のステップとの間隔を空けるため）
  countdown() {
    local seconds=${1:-3}
    for i in $(seq "$seconds" -1 1); do
      printf "\rインストール開始まで: %2d秒 " "$i"
      sleep 1
    done
    printf "\r%-40s\r" ""
  }

  CURRENT_STEP="GitHub CLI のインストール"
  echo "=== $CURRENT_STEP ==="
  if command -v gh > /dev/null 2>&1; then
    echo "→ 既にインストール済みのためスキップします。（$(gh --version | head -n 1)）"
  else
    countdown 3
    sudo apt install -y curl
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
  fi

  echo ""
  CURRENT_STEP="Claude CLI のインストール"
  echo "=== $CURRENT_STEP ==="
  export PATH="$HOME/.local/bin:$PATH"
  if command -v claude > /dev/null 2>&1; then
    echo "→ 既にインストール済みのためスキップします。（$(claude --version 2>&1 | head -n 1)）"
  else
    countdown 3
    curl -fsSL https://claude.ai/install.sh | bash
    append_bashrc_once 'export PATH="$HOME/.local/bin:$PATH"'
  fi

  echo ""
  CURRENT_STEP="GitHub Copilot の案内"
  echo "=== $CURRENT_STEP ==="
  echo "※ スクリプト完了後に以下のコマンドを手動で実行してください："
  echo "  gh copilot suggest \"list files\""

  echo ""
  CURRENT_STEP="JDK 17 のインストール"
  echo "=== $CURRENT_STEP ==="
  if dpkg -s openjdk-17-jdk > /dev/null 2>&1; then
    echo "→ 既にインストール済みのためスキップします。（$(java -version 2>&1 | head -n 1)）"
  else
    countdown 3
    sudo apt install -y openjdk-17-jdk
  fi
  JAVA_HOME_VAL=$(dirname $(dirname $(readlink -f $(which java))))
  append_bashrc_once "export JAVA_HOME=$JAVA_HOME_VAL"
  append_bashrc_once 'export PATH=$JAVA_HOME/bin:$PATH'
  export JAVA_HOME=$JAVA_HOME_VAL
  export PATH=$JAVA_HOME/bin:$PATH

  echo ""
  CURRENT_STEP="Maven のインストール"
  echo "=== $CURRENT_STEP ==="
  MVN_VERSION=3.9.15
  if [ -x /opt/maven/bin/mvn ]; then
    echo "→ 既にインストール済みのためスキップします。（$(/opt/maven/bin/mvn -version 2>&1 | head -n 1)）"
  else
    countdown 3
    cd ~
    rm -f apache-maven-${MVN_VERSION}-bin.tar.gz
    wget https://archive.apache.org/dist/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz
    tar -xzf apache-maven-${MVN_VERSION}-bin.tar.gz
    sudo rm -rf /opt/maven
    sudo mv apache-maven-${MVN_VERSION} /opt/maven
    rm apache-maven-${MVN_VERSION}-bin.tar.gz
  fi
  append_bashrc_once 'export M2_HOME=/opt/maven'
  append_bashrc_once 'export PATH=$M2_HOME/bin:$PATH'

  echo ""
  echo "=== セットアップ完了 ==="
  echo "※ 環境変数を反映するため、exit で WSL を抜けて wsl で入り直してください。"
  echo "※ 入り直したあと bash setup.sh --check でインストール状況を確認できます。"
  echo "※ GitHub Copilot のインストールがまだの場合は手動で実行してください。"
  echo "    gh copilot suggest \"list files\""
}

# ===== エントリポイント =====
if [ "$1" = "--check" ]; then
  run_check
else
  echo "これは「インストール実行」です。確認だけなら: bash setup.sh --check"
  read -p "セットアップ（インストール）を実行しますか？ [y/N]: " ANS
  if [ "$ANS" != "y" ] && [ "$ANS" != "Y" ]; then
    echo "中止しました。確認のみは bash setup.sh --check で実行できます。"
    exit 0
  fi
  run_setup
fi
