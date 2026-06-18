# 開発環境クリーンアップ手順

## 概要

研修終了後、PC を**セットアップ完了後の状態**（ツール類はそのまま、認証・研修データは無し）に戻す手順です。
**WSL側** と **Windows側** の2部構成で実施します。

| | クリーンアップ内容 |
|---|---|
| **WSL側** | Claude Code 認証解除 ／ GitHub CLI 認証解除（下流工程研修のみ）／ Claude Code 履歴削除 ／ git・bash の個人痕跡削除 ／ 研修資料削除 ／ VSCode の標準外拡張機能の確認・削除 |
| **Windows側** | ブラウザ（Chrome・Edge）の Cookie・閲覧履歴・ブックマーク・タブ/セッション削除 ／ メモ帳の未保存タブ削除 ／ Zoom のログイン情報削除 ／ ダウンロードフォルダの全削除 ／ ピクチャのスクリーンショット削除 ／ ごみ箱を空にする |

> **残すもの:** WSL/Ubuntu 本体、VSCode、`gh`・`claude`・JDK・Maven などのツール類と環境変数は削除しません（環境は変更しません）。

---

## クリーンアップ

### 1. ブラウザ・Zoom の手動ログアウト

スクリプトでローカルの認証データを消す前に、各サービスでログアウトしておくとサーバー側セッションも無効化されます。

1. ブラウザで https://claude.ai を開き、左下のユーザーアイコン → **「Log out」**
2. Zoom デスクトップアプリを起動し、右上のプロフィールアイコン → **「サインアウト」**

---

### 2. WSL側のクリーンアップ

以下の **A**（スクリプトで一括）または **B**（手動で1つずつ）のどちらかを実施する。**A を推奨**する。

---

#### A. スクリプトで一括（推奨）

##### A-1. 実行（クリーンアップ＋自動確認）

VSCode のメニューバー → **Terminal** → **New Terminal**（または `Ctrl+@`）で VSCode 内のターミナルを開き、以下を実行する。

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.sh -o cleanup.sh
```

```bash
# 実行（確認プロンプトに y で開始）
bash cleanup.sh
```

確認に `y` で答えると認証解除・履歴削除が進み、最後にホーム直下の一覧（隠しファイル除く）が表示される。削除する研修資料の名前（ファイル/フォルダ可）を入力する。複数あれば繰り返し入力でき、**無ければ／削除し終えたら空欄のまま Enter** で終了する。続いて、標準セット外の VSCode 拡張があれば一覧表示されるので、`y` でまとめてアンインストールできる。

削除が終わると、続けて**確認（点検）が自動で実行される**ので、別途コマンドを打つ必要はない。

> **VSCode 拡張機能:** 標準セット（WSL／Java／Spring Boot／Office Viewer〔上流工程研修のみ〕とその関連）外の拡張は、上記のとおりクリーンアップ実行中に一覧表示され `y` で削除できる（研修生が追加した拡張の整理）。確認（`--check`）では削除せず `[NG]` で残存を知らせるだけ。手動で消すなら Extensions view（`Ctrl+Shift+X`）→ 歯車アイコン → **Uninstall**。
> ※ 拡張の検出・削除は `code` コマンドを使うため、**VSCode 内の WSL ターミナル**で実行する。`code` が無い場合は `[--]`（スキップ）と表示される。

> **補足:** 後から点検し直したい場合は `bash cleanup.sh --check`（read-only。何度でも安全）。
> **補足:** bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。

##### A-2. 後片付け

確認まで終わったら、ダウンロードしたスクリプトを削除する（後から再確認する場合は、先に `--check` を実行してから削除する）。

```bash
# 後片付け
rm cleanup.sh
```

---

#### B. 手動で1つずつ

上から順に実行する。

##### B-1. Claude Code 認証解除

```bash
# Claude Code 認証解除（認証情報ファイルを削除。claude logout は対話画面が開く場合があるため使わない）
rm -f ~/.claude/.credentials.json
```

##### B-2. GitHub CLI 認証解除（下流工程研修のみ）

```bash
# GitHub CLI 認証解除（下流工程研修のみ）
gh auth logout
```

##### B-3. Claude Code 履歴削除

```bash
# Claude Code の会話・プロジェクト履歴削除
rm -rf ~/.claude ~/.claude.json ~/.claude.json.backup
```

##### B-4. git・bash の個人痕跡削除

```bash
# git・bash の個人痕跡削除
rm -f ~/.gitconfig
history -c && : > ~/.bash_history
```

##### B-5. 研修資料の削除

```bash
# 研修資料の削除（<研修資料の名前> を実際の名前に置換。複数あれば名前を変えて繰り返す）
rm -rf ~/<研修資料の名前>
```

##### B-6. 点検（手動）

削除後、こちらで点検する（各項目に OK/NG が表示される）。

```bash
# 確認（手動。スクリプトを使わず点検する）
ls -a ~                                          # 研修資料・痕跡が残っていないか目視
test -e ~/.claude && echo "NG: Claude 履歴/認証 残存" || echo "OK: Claude なし"
test -f ~/.gitconfig && echo "NG: gitconfig 残存" || echo "OK: gitconfig なし"
gh auth status >/dev/null 2>&1 && echo "NG: GitHub 認証残存（下流のみ）" || echo "OK: GitHub 未認証"
command -v gh claude java mvn                     # ツールが残っているか（パスが出れば OK）
```

---

### 3. VSCode の「最近開いたフォルダ」履歴の削除

VSCode を起動し、**File** → **Open Recent** → **Clear Recently Opened...** を選択する。

> 研修プロジェクトのパスが履歴に残るのを防ぐための手順です。

---

### 4. Windows側のクリーンアップ

Windows のスタートメニューで **「PowerShell」** を検索して起動する。

以下の **A**（スクリプトで一括）または **B**（手動で1つずつ）のどちらかを実施する。**A を推奨**する。

---

#### A. スクリプトで一括（推奨）

##### A-1. 実行（クリーンアップ＋自動確認）

PowerShell で以下を実行する（スクリプトは先に取得しておくと、クリーンアップ後にブラウザを開き直さずに済む）。

```powershell
# ダウンロード（TEMP に保存。作業フォルダの権限に依存しない）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.ps1 -OutFile "$env:TEMP\cleanup.ps1"
```

> **補足:** `アクセスが拒否されました` と出る場合は、保存先フォルダの書き込み権限が原因です。`$env:TEMP` に保存すれば回避できます（管理者権限は不要）。

> **注意:** 実行前に、ダウンロードフォルダを **VSCode で開いている**場合は **File → Close Folder** で閉じる（開いたままだとロックされて削除できません）。

```powershell
# 実行（確認プロンプトが出るので y で開始。確認のみは末尾に -Check を付ける）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1"
```

実行中、`y` の入力を2回求められる（「開始」と「ダウンロードフォルダ削除」）。いずれも `y` で進めると、概要の表の内容（ブラウザ・メモ帳・Zoom の終了とデータ削除、ダウンロード／スクリーンショット削除、ごみ箱の空化）が実行され、続けて**確認（点検）が自動で実行される**。

> **補足:** 後から点検し直したい場合は `powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1" -Check`（read-only。何度でも安全）。

##### A-2. デスクトップ・ドキュメントの余分なファイル確認

確認（自動実行または `-Check`）の出力に、**デスクトップ／ドキュメント**にあるファイル・フォルダ一覧が `[情報]` として表示される（合否判定はしない）。`Visual Studio Code` などセットアップ手順で作られたもの以外（研修生が作成したファイル・ショートカット等）があれば削除する。

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
> 削除後にもう一度 `cleanup.ps1 -Check` を実行すると、消えたか確認できます。

##### A-3. 後片付け

確認まで終わったら、ダウンロードしたスクリプトを削除する（後から再確認する場合は、先に `-Check` を実行してから削除する）。

```powershell
# 後片付け
Remove-Item "$env:TEMP\cleanup.ps1" -ErrorAction SilentlyContinue
```

---

#### B. 手動で1つずつ

PowerShell で上から順に実行する。

##### B-1. ブラウザ・メモ帳・Zoom を終了

```powershell
# ブラウザ・メモ帳・Zoom を終了する（未保存内容ごと閉じる）
Get-Process chrome, msedge, notepad, Zoom -ErrorAction SilentlyContinue | Stop-Process -Force
```

##### B-2. ブラウザのデータ削除

```powershell
# ブラウザ（Chrome・Edge）の Cookie・履歴・ブックマーク・タブ/セッションを削除
$targets = 'Network\Cookies','Cookies','History','Bookmarks','Bookmarks.bak',
           'Current Session','Current Tabs','Last Session','Last Tabs','Sessions','Top Sites','Visited Links'
"$env:LOCALAPPDATA\Google\Chrome\User Data\Default", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" | ForEach-Object {
  $prof = $_
  $targets | ForEach-Object { Remove-Item (Join-Path $prof $_) -Recurse -Force -ErrorAction SilentlyContinue }
}
```

##### B-3. メモ帳の未保存タブ削除

```powershell
# メモ帳の未保存タブを削除
Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState\TabState\*" -Recurse -Force -ErrorAction SilentlyContinue
```

##### B-4. Zoom のログイン情報削除

```powershell
# Zoom のログイン情報を削除（次回起動時に再ログインが必要＝ログアウト状態になる）
Remove-Item "$env:APPDATA\Zoom\data" -Recurse -Force -ErrorAction SilentlyContinue
```

##### B-5. ダウンロードフォルダを空にする

```powershell
# ダウンロードフォルダの中身を全削除（desktop.ini は除く）
Get-ChildItem "$env:USERPROFILE\Downloads" -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force
```

##### B-6. ピクチャのスクリーンショット削除

```powershell
# ピクチャのスクリーンショットを削除（Snipping Tool の自動保存・Win+PrtScn の保存先。desktop.ini は除く）
$shots = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Screenshots'
if (Test-Path $shots) { Get-ChildItem $shots -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
```

##### B-7. ごみ箱を空にする

```powershell
# ごみ箱を空にする
Clear-RecycleBin -Force
```

##### B-8. 点検（手動）

削除後、こちらで点検する（各項目に OK/NG が表示される）。

```powershell
# 確認（手動。スクリプトを使わず点検する）
$dl = (Get-ChildItem "$env:USERPROFILE\Downloads" -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' }).Count
if ($dl -eq 0) { Write-Host "OK: ダウンロードフォルダ 空" } else { Write-Host "NG: ダウンロード $dl 件残存" }
$shots = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Screenshots'
$sc = (Get-ChildItem $shots -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' }).Count
if ($sc -eq 0) { Write-Host "OK: スクリーンショット なし" } else { Write-Host "NG: スクリーンショット $sc 件残存" }
if (Test-Path "$env:APPDATA\Zoom\data") { Write-Host "NG: Zoom ログイン情報 残存" } else { Write-Host "OK: Zoom ログインなし" }
foreach ($p in @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History")) {
  if (Test-Path $p) { Write-Host "NG: ブラウザ履歴 残存 ($p)" } else { Write-Host "OK: ブラウザ履歴なし ($p)" }
}
```
