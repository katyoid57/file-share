# アカウント連携と起動手順

## 連絡先

**APD GrowthTech推進部**  
apd-gt-dpt@idenet.co.jp

**個人連絡先**  
代表：春木 　080-0000-0000  

---

## WSL起動手順

### 1. VSCode を起動する

Windows のスタートメニューまたはタスクバーから **「Visual Studio Code」** を起動する。

### 2. WSL に接続する

VSCode 左下の **`><`** アイコンをクリックし、**「Connect to WSL」** を選択する。

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

> **注意:** アカウント作成には会社メールアドレスを使用すること。

| アカウント | 作成先 |
|---|---|
| Claude Code アカウント | https://claude.ai/signup |
| GitHub アカウント（下流工程研修のみ） | https://github.com/signup |

---

### 疎通確認

認証前に外部サービスへの接続を確認する。

```bash
curl -s https://claude.ai > /dev/null && echo "Claude.ai: OK" || echo "Claude.ai: NG"
```

```bash
# 下流工程研修のみ
curl -s https://github.com > /dev/null && echo "GitHub: OK" || echo "GitHub: NG"
```

> すべて `OK` と表示されれば問題ない。`NG` の場合はネットワーク設定を確認すること。解決が難しそうであればAPD GrowthTech推進部へ連絡すること。

---

### Claude Code 認証

> ※ 以下の手順は 2026/04 現在の画面フローです。アップデートにより表示が変わる場合があります。

```bash
claude
```

起動後、以下の順に操作する：

1. **テーマ選択**が表示される → 好みのテーマを選択して `Enter`
2. **ログイン方法の選択**が表示される → ログイン方法を選択して `Enter`
3. ターミナルに **URL** が表示される → ブラウザで開く
4. ブラウザに **「Claude Code が Claude chat アカウントへの接続を希望しています」** と表示される → **「承認」** ボタンをクリック
5. ブラウザに **認証コード** が表示される → ターミナルに貼り付けて `Enter`
6. ターミナルに **「Login successful. Press Enter to continue」** と表示される → `Enter`
7. **セキュリティノート**が表示される → `Enter` で次へ
8. **ターミナル統合の設定**（Terminal setup）の選択が表示される → 選択して `Enter`
9. **フォルダの信頼確認**（セキュリティガイド）が表示される → 信頼する場合は許可して進む

> 以上で認証完了。`exit` または `Ctrl+C` で終了できる。

---

### GitHub CLI 認証（下流工程研修のみ）

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
