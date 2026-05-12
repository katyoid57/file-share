#!/bin/bash
set -e

echo "=== GitHub CLI のインストール ==="
sudo apt install -y curl
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

echo "=== Claude CLI のインストール ==="
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"

echo "=== GitHub Copilot のインストール ==="
echo "※ スクリプト完了後に以下のコマンドを手動で実行してください："
echo "  gh copilot suggest \"list files\""

echo "=== JDK 17 のインストール ==="
sudo apt install -y openjdk-17-jdk
JAVA_HOME_VAL=$(dirname $(dirname $(readlink -f $(which java))))
echo "export JAVA_HOME=$JAVA_HOME_VAL" >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
export JAVA_HOME=$JAVA_HOME_VAL
export PATH=$JAVA_HOME/bin:$PATH

echo "=== Maven のインストール ==="
MVN_VERSION=3.9.15
cd ~
wget https://downloads.apache.org/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz
tar -xzf apache-maven-${MVN_VERSION}-bin.tar.gz
sudo mv apache-maven-${MVN_VERSION} /opt/maven
rm apache-maven-${MVN_VERSION}-bin.tar.gz
echo 'export M2_HOME=/opt/maven' >> ~/.bashrc
echo 'export PATH=$M2_HOME/bin:$PATH' >> ~/.bashrc

echo ""
echo "=== セットアップ完了 ==="
echo "※ 環境変数を反映するため、ターミナルを再起動してください。"
echo "※ GitHub Copilot のインストールがまだの場合は手動で実行してください。"
echo "    gh copilot suggest \"list files\""
