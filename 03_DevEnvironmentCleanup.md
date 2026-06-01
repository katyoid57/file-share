# 開発環境クリーンアップ手順

## 概要

研修終了後、PC を**セットアップ完了後の状態**（ツール類はそのまま、認証・研修データは無し）に戻す手順です。
**WSL側** と **Windows側** の2部構成で実施します。

| | クリーンアップ内容 |
|---|---|
| **WSL側** | Claude Code 認証解除 ／ GitHub CLI 認証解除（下流工程研修のみ）／ Claude Code 履歴削除 ／ git・bash の個人痕跡削除 ／ 研修資料フォルダ削除 |
| **Windows側** | ブラウザ（Chrome・Edge）の Cookie・閲覧履歴・ブックマーク削除 ／ ダウンロードフォルダの全削除 ／ ごみ箱を空にする |

> **残すもの:** WSL/Ubuntu 本体、VSCode、`gh`・`claude`・JDK・Maven などのツール類と環境変数は削除しません（環境は変更しません）。

---

## 手順0. ブラウザを手動でログアウトする（先に実施）

スクリプトで Cookie を削除する前に、ブラウザで明示的にログアウトしておくとサーバー側セッションも無効化され確実です。

1. ブラウザで https://claude.ai を開き、右上のアカウントアイコン → **「Log out」**
2. （**下流工程研修のみ**）https://github.com を開き、右上のアイコン → **「Sign out」**

---

## 手順1. WSL側のクリーンアップ

VSCode のメニューバー → **ターミナル** → **新しいターミナル**（または `Ctrl+@`）で VSCode 内のターミナルを開き、以下を実行する。

```bash
bash ~/scripts/cleanup.sh
```

実行後、削除する研修フォルダ名の入力を求められるので入力する。

> **補足:** bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。

### シェルスクリプトをダウンロードして実行する場合

`~/scripts/` が無い場合は、WSL ターミナルで以下を実行する。

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.sh -o cleanup.sh
```

```bash
# 実行
bash cleanup.sh
```

```bash
# 後片付け
rm cleanup.sh
```

### check-cleanup.sh でクリーンアップ確認

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/check-cleanup.sh -o check-cleanup.sh
```

```bash
# 実行
bash check-cleanup.sh
```

```bash
# 後片付け
rm check-cleanup.sh
```

> 各項目に `[OK]` が表示されていればクリーンアップ完了。`[NG]` の場合は該当ステップを見直すこと。

### 手動で実施する場合

```bash
# 1. Claude Code 認証解除
claude logout

# 2. GitHub CLI 認証解除（下流工程研修のみ）
gh auth logout

# 3. Claude Code の会話・プロジェクト履歴削除
rm -rf ~/.claude ~/.claude.json

# 4. git・bash の個人痕跡削除
rm -f ~/.gitconfig
history -c && : > ~/.bash_history

# 5. 研修資料フォルダの削除
rm -rf ~/（研修フォルダ名）
```

---

## 手順2. Windows側のクリーンアップ

Windows のスタートメニューで **「PowerShell」** を検索して起動し、以下を実行する。

```powershell
# ダウンロード
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.ps1 -OutFile cleanup.ps1
```

```powershell
# 実行
powershell -ExecutionPolicy Bypass -File .\cleanup.ps1
```

```powershell
# 後片付け
Remove-Item cleanup.ps1
```

実行すると、ブラウザ（Chrome・Edge）が終了され、Cookie・閲覧履歴・ブックマークが削除される。続いてダウンロードフォルダの全削除確認を求められるので `y` で実行する。最後にごみ箱が空になる。

> **注意:** ダウンロードフォルダは**中身がすべて削除**されます。残したいファイルがある場合は事前に退避してください。
> **注意:** ブラウザは自動で終了されます。未保存の作業がある場合は事前に保存してください。

### check-cleanup.ps1 でクリーンアップ確認

```powershell
# ダウンロード
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/check-cleanup.ps1 -OutFile check-cleanup.ps1
```

```powershell
# 実行
powershell -ExecutionPolicy Bypass -File .\check-cleanup.ps1
```

```powershell
# 後片付け
Remove-Item check-cleanup.ps1
```

> 各項目に `[OK]` が表示されていればクリーンアップ完了。`[NG]` の場合は該当ステップを見直すこと。

---

## 手順3. VSCode の「最近開いたフォルダ」履歴を消す

VSCode を起動し、**ファイル** → **最近使用したもの** → **最近開いた項目をクリア** を選択する。

> 研修プロジェクトのパスが履歴に残るのを防ぐための手順です。
