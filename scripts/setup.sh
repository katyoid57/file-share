#!/bin/bash
set -e

RED='\033[0;31m'
NC='\033[0m'

CURRENT_STEP=""
trap 'echo -e "${RED}[ERROR]${NC} ${CURRENT_STEP} で失敗しました（line $LINENO）。もう一度 bash setup.sh を実行すると、成功済みのステップはスキップされます。"; exit 1' ERR

# 同じ行が既に ~/.bashrc にある場合は追記しない
append_bashrc_once() {
  local line=$1
  grep -qxF "$line" ~/.bashrc 2>/dev/null || echo "$line" >> ~/.bashrc
}

CURRENT_STEP="GitHub CLI のインストール"
echo "=== $CURRENT_STEP ==="
if command -v gh > /dev/null 2>&1; then
  echo "→ 既にインストール済みのためスキップします。（$(gh --version | head -n 1)）"
else
  sudo apt install -y curl
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
fi

CURRENT_STEP="Claude CLI のインストール"
echo "=== $CURRENT_STEP ==="
export PATH="$HOME/.local/bin:$PATH"
if command -v claude > /dev/null 2>&1; then
  echo "→ 既にインストール済みのためスキップします。（$(claude --version 2>&1 | head -n 1)）"
else
  curl -fsSL https://claude.ai/install.sh | bash
  append_bashrc_once 'export PATH="$HOME/.local/bin:$PATH"'
fi

CURRENT_STEP="GitHub Copilot の案内"
echo "=== $CURRENT_STEP ==="
echo "※ スクリプト完了後に以下のコマンドを手動で実行してください："
echo "  gh copilot suggest \"list files\""

CURRENT_STEP="JDK 17 のインストール"
echo "=== $CURRENT_STEP ==="
if dpkg -s openjdk-17-jdk > /dev/null 2>&1; then
  echo "→ 既にインストール済みのためスキップします。（$(java -version 2>&1 | head -n 1)）"
else
  sudo apt install -y openjdk-17-jdk
fi
JAVA_HOME_VAL=$(dirname $(dirname $(readlink -f $(which java))))
append_bashrc_once "export JAVA_HOME=$JAVA_HOME_VAL"
append_bashrc_once 'export PATH=$JAVA_HOME/bin:$PATH'
export JAVA_HOME=$JAVA_HOME_VAL
export PATH=$JAVA_HOME/bin:$PATH

CURRENT_STEP="Maven のインストール"
echo "=== $CURRENT_STEP ==="
MVN_VERSION=3.9.15
if [ -x /opt/maven/bin/mvn ]; then
  echo "→ 既にインストール済みのためスキップします。（$(/opt/maven/bin/mvn -version 2>&1 | head -n 1)）"
else
  cd ~
  rm -f apache-maven-${MVN_VERSION}-bin.tar.gz
  wget https://downloads.apache.org/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz
  tar -xzf apache-maven-${MVN_VERSION}-bin.tar.gz
  sudo rm -rf /opt/maven
  sudo mv apache-maven-${MVN_VERSION} /opt/maven
  rm apache-maven-${MVN_VERSION}-bin.tar.gz
fi
append_bashrc_once 'export M2_HOME=/opt/maven'
append_bashrc_once 'export PATH=$M2_HOME/bin:$PATH'

echo ""
echo "=== セットアップ完了 ==="
echo "※ 環境変数を反映するため、ターミナルを再起動してください。"
echo "※ GitHub Copilot のインストールがまだの場合は手動で実行してください。"
echo "    gh copilot suggest \"list files\""
