# 研修環境セットアップ

## 準備

- VSCode利用申請
- ClaudeCodeアカウント作成

---

## セットアップ

### 1. 管理者権限アカウントでログインする

### 2. WSL をインストールして再起動する

```powershell
wsl --install
```

### 3. Ubuntu をインストールする

```bash
# 利用可能なLinux配布を確認
wsl.exe --list --online

# インストール
wsl.exe --install Ubuntu-22.04
```

ユーザ名とパスワードを設定（ユーザ名は英小文字・数字）

```bash
Enter new UNIX username:
Enter new UNIX password:
```

```bash
# 起動確認
uname -a

# 最新化
sudo apt update
sudo apt upgrade -y
```

### 4. GitHub CLI のインストール

```bash
# GitHub CLI 公式リポジトリを追加
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

# apt リポジトリ登録
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# インストール
sudo apt update
sudo apt install gh -y

# 確認
gh version
```

### 5. Claude CLI のインストール

```bash
# Anthropic 公式のネイティブインストーラー
curl -fsSL https://claude.ai/install.sh | bash

# 確認
claude --version

# ~/.local/bin を永続的に PATH に追加
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc

# 確認
which claude
```

### 6. Copilot CLI のインストール

```bash
# インストール
gh extension install github/gh-copilot

# 確認
gh copilot --help
```

### 7. JDK 17 をインストールする

```bash
# インストール
sudo apt install -y openjdk-17-jdk

# 確認
java -version
```

> **結果例**
> ```
> openjdk version "17.x.x" ...
> ```

```bash
# JAVA_HOME を永続的に設定
echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 確認
echo $JAVA_HOME
```

### 8. Maven 3.8以上 をインストールする

> **注意:** apt の Maven はバージョンが古い（3.6系）ため、公式バイナリを手動インストールする。  
> 最新バージョンは https://maven.apache.org/download.cgi で確認。

```bash
MVN_VERSION=3.9.9

# ダウンロード
wget https://downloads.apache.org/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz

# 展開・配置
tar -xzf apache-maven-${MVN_VERSION}-bin.tar.gz
sudo mv apache-maven-${MVN_VERSION} /opt/maven
rm apache-maven-${MVN_VERSION}-bin.tar.gz

# 環境変数を永続的に設定
echo 'export M2_HOME=/opt/maven' >> ~/.bashrc
echo 'export PATH=$M2_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 確認
mvn -version
```

> **結果例**
> ```
> Apache Maven 3.9.x ...
> ```

### 9. Node.js 20（LTS）をインストールする

```bash
# NodeSource 公式スクリプトでリポジトリを追加（Node.js 20 LTS）
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# インストール
sudo apt install -y nodejs

# 確認
node --version
npm --version
```

> **結果例**
> ```
> v20.x.x
> 10.x.x
> ```

### 10. VSCode をインストールする（利用申請完了後に実施）

> **注意:** WSL 上では VSCode 本体は Windows 側にインストールし、WSL 拡張機能で接続する。

1. Windows ブラウザで以下のページを開き、VSCode 1.114 のインストーラーをダウンロード・インストール  
   https://code.visualstudio.com/updates/v1_114  
   → ページ右上の"ダウンロード"ボタンを押下し、 **Windows** 向けインストーラーを選択してダウンロード  
   → インストール時に **「PATHへの追加」** オプションにチェックを入れる

2. VSCode を起動し、以下の拡張機能をインストール  
   拡張機能パネル（`Ctrl+Shift+X`）を開き、それぞれ検索してインストールする

   | 拡張機能名 | 拡張機能ID |
   |---|---|
   | WSL | `ms-vscode-remote.remote-wsl` |
   | Extension Pack for Java | `vscjava.vscode-java-pack` |
   | Spring Boot Extension Pack | `vmware.vscode-boot-dev-pack` |

   またはターミナルからまとめてインストール：

   ```powershell
   code --install-extension ms-vscode-remote.remote-wsl
   code --install-extension vscjava.vscode-java-pack
   code --install-extension vmware.vscode-boot-dev-pack
   ```

3. WSL ターミナルから VSCode を起動

```bash
code .
```

> ブラウザが開き VSCode Server のインストールが自動で行われた後、WSL 接続状態の VSCode が起動する。

4. 起動確認  
   左下に **「WSL: Ubuntu-22.04」** と表示されていれば接続成功
