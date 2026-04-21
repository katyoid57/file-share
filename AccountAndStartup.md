# アカウント連携と起動手順

## 毎日の起動手順

### 1. VSCode を起動する

Windows のスタートメニューまたはタスクバーから **「Visual Studio Code」** を起動する。

### 2. WSL に接続する

VSCode 左下の **`><`** アイコンをクリックし、**「WSLへの接続」** を選択する。

> または `Ctrl+Shift+P` → `WSL: Connect to WSL` で接続できる。  
> 左下のステータスバーに **「WSL: Ubuntu-22.04」** と表示されれば接続完了。

### 3. プロジェクトフォルダを開く

メニューバー → **ファイル** → **フォルダーを開く**（`Ctrl+K, Ctrl+O`）から  
WSL 上のプロジェクトディレクトリを選択する。

> 2回目以降は **ファイル** → **最近使用したもの** から直接開ける。

### 4. ターミナルを開いて作業する

`Ctrl+@` または メニューバー → **ターミナル** → **新しいターミナル** で  
WSL ターミナルが VSCode 内に開く。以降の作業はここで行う。

---

## セットアップ中のアカウント連携（初回のみ）

> セットアップ手順書と並行して実施する。それぞれ指定のタイミングで行うこと。

### 事前準備

セットアップ開始前に以下のアカウントを作成しておく：

| アカウント | 作成先 |
|---|---|
| GitHub アカウント | https://github.com/signup |
| Claude Code アカウント | https://claude.ai/signup |

---

### GitHub CLI 認証

> **タイミング:** セットアップ手順のステップ4（GitHub CLI インストール）完了直後に実施する。

```bash
gh auth login
```

以下の順に選択する（矢印キーで選択し Enter）：

| 質問 | 選択・入力 |
|---|---|
| What account do you want to log into? | `GitHub.com` |
| What is your preferred protocol for Git operations? | `HTTPS` |
| Authenticate Git with your GitHub credentials? | `Yes` |
| How would you like to authenticate GitHub CLI? | `Login with a web browser` |

ターミナルにワンタイムコード（例：`XXXX-XXXX`）が表示されるので手順に従う：

1. 表示されたURLをブラウザで開く
2. GitHub にログインした状態でワンタイムコードを入力する
3. 認証が完了したらターミナルに戻る

```bash
# 認証確認
gh auth status
```

> **結果例**
> ```
> ✓ Logged in as <ユーザネーム>
> ✓ Git operations configured for HTTPS
> ```

---

### Claude Code 認証

> **タイミング:** セットアップ手順のステップ5（Claude CLI インストール）完了直後に実施する。

```bash
claude
```

起動後、以下の順に操作する：

1. 利用規約が表示される → `Enter` で同意して進む
2. データ収集の確認が表示される → `Enter` でスキップ
3. ブラウザが自動で開き、Claude へのログイン画面が表示される
4. claude.ai アカウントでログインし、連携を許可する
5. ブラウザでの認証が完了したらターミナルに戻る
6. テーマや設定の確認画面が表示される → 各プロンプトで `Enter` を押して進む

> ターミナルに `>` プロンプトが表示されれば起動完了。  
> `exit` または `Ctrl+C` で終了できる。
