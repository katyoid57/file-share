# 開発環境クリーンアップ手順

## 概要

研修終了後、PC を**セットアップ完了後の状態**（ツール類はそのまま、認証・研修データは無し）に戻す手順です。
**WSL側** と **Windows側** の2部構成で実施します。

| | クリーンアップ内容 |
|---|---|
| **WSL側** | Claude Code 認証解除 ／ GitHub CLI 認証解除（下流工程研修のみ）／ Claude Code 履歴削除 ／ git・bash の個人痕跡削除 ／ 研修資料フォルダ削除 |
| **Windows側** | ブラウザ（Chrome・Edge）の Cookie・閲覧履歴・ブックマーク・タブ/セッション削除 ／ メモ帳の未保存タブ削除 ／ ダウンロードフォルダの全削除 ／ ごみ箱を空にする |

> **残すもの:** WSL/Ubuntu 本体、VSCode、`gh`・`claude`・JDK・Maven などのツール類と環境変数は削除しません（環境は変更しません）。

---

## 手順0. ブラウザを手動でログアウトする（先に実施）

スクリプトで Cookie を削除する前に、ブラウザで明示的にログアウトしておくとサーバー側セッションも無効化され確実です。

1. ブラウザで https://claude.ai を開き、左下のユーザーアイコン → **「Log out」**
2. （**下流工程研修のみ**）https://github.com を開き、右上のアイコン → **「Sign out」**

---

## 手順1. WSL側のクリーンアップ

VSCode のメニューバー → **Terminal** → **New Terminal**（または `Ctrl+@`）で VSCode 内のターミナルを開き、以下を実行する。

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

実行後、ホーム直下のフォルダ一覧が表示され、削除する研修フォルダ名の入力を求められるので入力する。

> **補足:** 研修資料を既に手動で削除済みの場合は、**空欄のまま Enter** でスキップできる（無くても処理は止まらない）。
> **補足:** bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。

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
# 1. Claude Code 認証解除（認証情報ファイルを削除。claude logout は対話画面が開く場合があるため使わない）
rm -f ~/.claude/.credentials.json

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
# ダウンロード（TEMP に保存。作業フォルダの権限に依存しない）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.ps1 -OutFile "$env:TEMP\cleanup.ps1"
```

```powershell
# 実行
powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1"
```

```powershell
# 後片付け
Remove-Item "$env:TEMP\cleanup.ps1"
```

> **補足:** `アクセスが拒否されました` と出る場合は、保存先フォルダの書き込み権限が原因です。上記のとおり `$env:TEMP` に保存すれば回避できます（管理者権限は不要）。

実行すると、ブラウザ（Chrome・Edge）とメモ帳が終了され、ブラウザの Cookie・閲覧履歴・ブックマーク・タブ/セッション（最近閉じたタブ等）とメモ帳の未保存タブが削除される。続いてダウンロードフォルダの全削除確認を求められるので `y` で実行する。最後にごみ箱が空になる。

> **注意:** ダウンロードフォルダは**中身がすべて削除**されます。残したいファイルがある場合は事前に退避してください。
> **注意:** ブラウザとメモ帳は自動で終了されます。**未保存の内容は破棄されます**ので、残したい作業がある場合は事前に保存してください。

### check-cleanup.ps1 でクリーンアップ確認

```powershell
# ダウンロード（TEMP に保存）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/check-cleanup.ps1 -OutFile "$env:TEMP\check-cleanup.ps1"
```

```powershell
# 実行
powershell -ExecutionPolicy Bypass -File "$env:TEMP\check-cleanup.ps1"
```

```powershell
# 後片付け
Remove-Item "$env:TEMP\check-cleanup.ps1"
```

> 各項目に `[OK]` が表示されていればクリーンアップ完了。`[NG]` の場合は該当ステップを見直すこと。

---

## 手順3. VSCode の「最近開いたフォルダ」履歴を消す

VSCode を起動し、**File** → **Open Recent** → **Clear Recently Opened...** を選択する。

> 研修プロジェクトのパスが履歴に残るのを防ぐための手順です。

---

## 手順4. 仕上げ確認（セットアップ完了状態に戻ったか）

最後に、PC が**次の研修生に渡せる状態（＝セットアップ完了状態）**に戻っているかを確認する。

### 4-1. デスクトップ・ドキュメントの余分なファイル確認

手順2 の `check-cleanup.ps1` の出力に、**デスクトップ／ドキュメント**にあるファイル・フォルダ一覧が `[情報]` として表示される（合否判定はしない）。`Visual Studio Code` などセットアップ手順で作られたもの以外（研修生が作成したファイル・ショートカット等）があれば削除する。

削除する場合は、エクスプローラーで右クリック → 削除するか、PowerShell で以下を実行する（`<名前>` を一覧に出た実際の名前に置き換える）。

```powershell
# デスクトップのファイル/フォルダを削除
Remove-Item (Join-Path ([Environment]::GetFolderPath('Desktop')) "<名前>") -Recurse -Force
```

```powershell
# ドキュメントのファイル/フォルダを削除
Remove-Item (Join-Path ([Environment]::GetFolderPath('MyDocuments')) "<名前>") -Recurse -Force
```

> **注意:** `-Recurse -Force` は確認なしで削除します。`<名前>` が一覧に表示されたものと一致しているか確認してから実行してください。
> 削除後にもう一度 `check-cleanup.ps1` を実行すると、消えたか確認できます。

### 4-2. 開発環境が残っているか確認（check-setup.sh）

ツール類（`gh`・`claude`・JDK・Maven）が消えずに揃っているかを、`00_DevEnvironmentSetup.md` の確認スクリプトで点検する。WSL ターミナルで:

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/check-setup.sh -o check-setup.sh
```

```bash
# 実行
bash check-setup.sh
```

```bash
# 後片付け
rm check-setup.sh
```

> **すべて `[OK]`** であれば、開発環境はそのまま残っており、認証・個人データだけが消えた**セットアップ完了状態**に戻っている。これで次の研修生がそのまま研修を開始できる。
> もし `[NG]` が出た場合は、その項目を `00_DevEnvironmentSetup.md` の手順で再セットアップすること。
