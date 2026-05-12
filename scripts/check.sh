#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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
