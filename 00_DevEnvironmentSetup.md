# 研修環境セットアップ

## 準備

- VSCode利用申請
- ClaudeCodeアカウント作成

---

## セットアップ

### 1. 管理者権限アカウントでログインする

### 2. WSL をインストールする

コマンドプロンプトを**管理者として起動**する（スタートメニューで「cmd」を右クリック → **管理者として実行**）。

```cmd
wsl --install
```

インストール後、**PCを再起動する**。

再起動後、コマンドプロンプトを開き（管理者不要）、以下でインストールを確認する：

```cmd
wsl --version
```

> **結果例**
> ```
> WSL version: 2.x.x.x
> Kernel version: 5.15.x.x-microsoft-standard-WSL2
> Windows version: 10.0.x.x
> ```

### 3. Ubuntu をインストールする

```bash
# 利用可能なLinux配布を確認
wsl.exe --list --online

# インストール
wsl.exe --install Ubuntu-22.04
```

インストール後にユーザ名とパスワードの設定を求められる。

> ユーザ名・パスワードは別途各自に共有する。（ユーザ名は英小文字・数字）

```bash
# 起動確認
uname -a
```

> **結果例**
> ```
> Linux <hostname> 5.15.x.x-microsoft-standard-WSL2 #1 SMP ... x86_64 GNU/Linux
> ```

```bash
# 最新化
sudo apt update
sudo apt upgrade -y
```

### 4. GitHub CLI のインストール

```bash
# GitHub CLI 公式リポジトリを追加
sudo apt install -y curl
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

# apt リポジトリ登録
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# インストール
sudo apt update
sudo apt install -y gh

# 確認
gh version
```

> **結果例**
> ```
> gh version 2.x.x (2024-xx-xx)
> https://github.com/cli/cli/releases/tag/v2.x.x
> ```

### 5. Claude CLI のインストール

```bash
# Anthropic 公式のネイティブインストーラー
curl -fsSL https://claude.ai/install.sh | bash

# ~/.local/bin を永続的に PATH に追加
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 確認
claude --version
```

> **結果例**
> ```
> 2.x.x (Claude Code)
> ```

### 6. Copilot CLI のインストール

```bash
# 初回実行時にインストールを促されるので yes と答える
gh copilot suggest "list files"

# 確認
gh copilot --version
```

> **結果例**
> ```
> GitHub Copilot CLI 1.x.x
> Run 'copilot update' to check for updates.
> ```

### 7. JDK 17 をインストールする

```bash
# インストール
sudo apt install -y openjdk-17-jdk

# JAVA_HOME を永続的に設定
echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 確認
java -version
echo $JAVA_HOME
```

> **結果例**
> ```
> openjdk version "17.x.x" ...
> /usr/lib/jvm/java-17-openjdk-amd64
> ```

### 8. Maven 3.9 をインストールする

> **注意:** apt でインストールできる Maven はバージョンが古い（3.6系）のため、以下のコマンドで公式サイトから直接取得してインストールする。  
> 最新バージョンは https://maven.apache.org/download.cgi で確認。

```bash
# バージョン指定
MVN_VERSION=3.9.15
```

```bash
# ダウンロード
wget https://downloads.apache.org/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz
```

```bash
# 展開・配置・後片付け
tar -xzf apache-maven-${MVN_VERSION}-bin.tar.gz
sudo mv apache-maven-${MVN_VERSION} /opt/maven
rm apache-maven-${MVN_VERSION}-bin.tar.gz
```

```bash
# 環境変数を永続的に設定
echo 'export M2_HOME=/opt/maven' >> ~/.bashrc
echo 'export PATH=$M2_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 確認
mvn -version
```

> **結果例**
> ```
> Apache Maven 3.9.15 ...
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

3. WSL ターミナルから VSCode の接続確認を行う（初回のみ）

WSL ターミナルを開き、任意のディレクトリで以下を実行する：

```bash
cd ~
code .
```

> 初回は VSCode Server のインストールが自動で行われる（数分かかる場合がある）。  
> 完了すると VSCode ウィンドウが開く。

4. 起動確認  
   左下に **「WSL: Ubuntu-22.04」** と表示されていれば接続成功
