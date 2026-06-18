# 研修環境セットアップ手順

## 準備

- VSCode利用申請
- GitHubアカウント作成（セットアップ後でも可）
- ClaudeCodeアカウント作成（セットアップ後でも可）
- GitHub Copilot契約

---

## セットアップ

### 1. 管理者権限アカウントでのログイン

### 2. WSL のインストール

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

### 3. Ubuntu のインストール

```bash
# 利用可能なLinux配布を確認
wsl.exe --list --online
```

```bash
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

### 4. CLI・JDK・Maven のインストール

以下の **A**（シェルスクリプトで一括）または **B**（手動で1つずつ）のどちらかを実施する。**A を推奨**する。

#### ✅ A. シェルスクリプトで一括インストール（推奨）

##### A-1. setup.sh で一括インストール

WSL ターミナルで以下を実行する。

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/setup.sh -o setup.sh
```

```bash
# 実行（確認プロンプトが出るので y で開始。確認のみは bash setup.sh --check）
bash setup.sh
```

> **注意:** 後片付け（`rm setup.sh`）は、次の A-2 の確認まで終えてから行う（確認も同じ `setup.sh` を使うため）。

> **注意:** GitHub Copilot のインストールは `gh auth login` の認証完了後に手動で実行してください。
> ```
> gh copilot suggest "list files"
> ```

> **重要:** スクリプト完了後、`exit` で WSL を抜けて `wsl` で入り直してください。`~/.bashrc` の環境変数はシェルを再起動しないと反映されず、このまま次の確認手順に進むと Claude CLI と Maven が `[NG]` になります。

##### A-2. setup.sh --check でインストール確認

> **前提:** 上記 A-1 の完了後、`exit` → `wsl` で入り直した状態で実行してください。

```bash
# 確認（--check は確認のみ。インストールは行わない）
bash setup.sh --check
```

> 各項目に `[OK]` が表示されていればインストール完了。`[NG]` の場合は該当ステップを見直すこと。

##### A-3. 後片付け

確認まで終わったら、ダウンロードしたスクリプトを削除する。

```bash
# 後片付け
rm setup.sh
```

#### 🔧 B. 手動で1つずつインストール

##### B-1. GitHub CLI のインストール

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
```

```bash
# 確認
gh version
```

> **結果例**
> ```
> gh version 2.x.x (2024-xx-xx)
> https://github.com/cli/cli/releases/tag/v2.x.x
> ```

##### B-2. Claude CLI のインストール

```bash
# Anthropic 公式のネイティブインストーラー
curl -fsSL https://claude.ai/install.sh | bash

# ~/.local/bin を永続的に PATH に追加
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

```bash
# 確認
claude --version
```

> **結果例**
> ```
> 2.x.x (Claude Code)
> ```

##### B-3. GitHub Copilot のインストール

```bash
# 初回実行時にインストールを促されるので yes と答える
gh copilot suggest "list files"
```

> **補足:** インストール後に `Invalid command format` エラーが表示されることがあるが、インストール自体は成功しているため無視して問題ない。

```bash
# 確認
gh copilot --version
```

> **結果例**
> ```
> GitHub Copilot CLI 1.x.x
> Run 'copilot update' to check for updates.
> ```

##### B-4. JDK 17 のインストール

```bash
# インストール
sudo apt install -y openjdk-17-jdk

# JAVA_HOME を永続的に設定
echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

```bash
# 確認
java -version
echo $JAVA_HOME
```

> **結果例**
> ```
> openjdk version "17.x.x" ...
> /usr/lib/jvm/java-17-openjdk-amd64
> ```

##### B-5. Maven のインストール

> **注意:** apt でインストールできる Maven はバージョンが古い（3.6系）のため、以下のコマンドで公式サイトから直接取得してインストールする。

```bash
# ホームディレクトリに移動（WSLのLinuxファイルシステム上で作業するため）
cd ~
```

```bash
# バージョン指定・ダウンロード
MVN_VERSION=3.9.15
wget https://archive.apache.org/dist/maven/maven-3/${MVN_VERSION}/binaries/apache-maven-${MVN_VERSION}-bin.tar.gz
```

```bash
# 展開・配置・後片付け
MVN_VERSION=3.9.15
tar -xzf apache-maven-${MVN_VERSION}-bin.tar.gz
sudo mv apache-maven-${MVN_VERSION} /opt/maven
rm apache-maven-${MVN_VERSION}-bin.tar.gz
```

```bash
# 環境変数を永続的に設定
echo 'export M2_HOME=/opt/maven' >> ~/.bashrc
echo 'export PATH=$M2_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

```bash
# 確認
mvn -version
```

> **結果例**
> ```
> Apache Maven 3.9.15 ...
> ```

---

### 5. VSCode のインストール（利用申請完了後に実施）

> **注意:** WSL 上では VSCode 本体は Windows 側にインストールし、WSL 拡張機能で接続する。

1. Windows ブラウザで以下のページを開き、VSCode 1.114 のインストーラーをダウンロード・インストール  
   https://code.visualstudio.com/updates/v1_114  
   → ページ右上の"ダウンロード"ボタンを押下し、 **Windows** 向けインストーラーを選択してダウンロード  
   → インストール時に **「PATHへの追加」** オプションにチェックを入れる

2. VSCode を起動し、以下の拡張機能をインストール  
   Extensions view（`Ctrl+Shift+X`）を開き、それぞれ検索してインストールする

   | 拡張機能名 | 拡張機能ID |
   |---|---|
   | WSL | `ms-vscode-remote.remote-wsl` |
   | Extension Pack for Java | `vscjava.vscode-java-pack` |
   | Spring Boot Extension Pack | `vmware.vscode-boot-dev-pack` |

3. VSCode 左下の **`><`** アイコンをクリックし、**「Connect to WSL」** を選択する

> 初回は VSCode Server のダウンロードとインストールが自動で行われる（数分かかる場合がある）。

4. 起動確認  
   左下に **「WSL: Ubuntu-22.04」** と表示されていれば接続成功
