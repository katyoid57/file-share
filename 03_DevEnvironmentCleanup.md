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

VSCode のメニューバー → **Terminal** → **New Terminal**（または `Ctrl+@`）で VSCode 内のターミナルを開き、以下を実行する。

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.sh -o cleanup.sh
```

```bash
# 実行（確認プロンプトに y で開始）
bash cleanup.sh
```

確認に `y` で答えると認証解除・履歴削除が進み、最後にホーム直下の一覧（隠しファイル除く）が表示される。削除する研修資料の名前（ファイル/フォルダ可）を入力する。複数あれば繰り返し入力でき、**無ければ／削除し終えたら空欄のまま Enter** で終了する。

削除が終わると、続けて**確認（点検）が自動で実行される**ので、別途コマンドを打つ必要はない。

> **【1】個人データ（消すもの）が `[OK]`／`[--]`、【2】ツール（残すもの）が `[OK]`** であれば、次の研修生に渡せる状態。`[NG]` の場合は該当ステップを見直すこと。

> **VSCode 拡張機能:** `[NG]` で拡張機能IDが表示されたら、標準セット（WSL／Java／Spring Boot／Office Viewer〔上流工程研修のみ〕とその関連）外に研修生が追加した拡張です。不要なら Extensions view（`Ctrl+Shift+X`）で該当拡張を検索し、歯車アイコン → **Uninstall** で削除する。
> ※ 拡張機能の検出は `code` コマンドを使うため、**VSCode 内の WSL ターミナル**で実行する。`code` が見つからない場合は `[--]` と表示される。

> **補足:** 後から点検し直したい場合は `bash cleanup.sh --check`（read-only。何度でも安全）。済んだら `rm cleanup.sh` で後片付けする。
> **補足:** bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。

---

#### B. 手動で1つずつ

上から順に実行する。

```bash
# 1. Claude Code 認証解除（認証情報ファイルを削除。claude logout は対話画面が開く場合があるため使わない）
rm -f ~/.claude/.credentials.json
```

```bash
# 2. GitHub CLI 認証解除（下流工程研修のみ）
gh auth logout
```

```bash
# 3. Claude Code の会話・プロジェクト履歴削除
rm -rf ~/.claude ~/.claude.json ~/.claude.json.backup
```

```bash
# 4. git・bash の個人痕跡削除
rm -f ~/.gitconfig
history -c && : > ~/.bash_history
```

```bash
# 5. 研修資料の削除（<研修資料の名前> を実際の名前に置換。複数あれば名前を変えて繰り返す）
rm -rf ~/<研修資料の名前>
```

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

まず、**スクリプトをダウンロード**しておく。先に取得しておけば、クリーンアップ後にブラウザを開き直してスクリプトを取りに行く必要がなくなる。

```powershell
# ダウンロード（TEMP に保存。作業フォルダの権限に依存しない）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.ps1 -OutFile "$env:TEMP\cleanup.ps1"
```

> **補足:** `アクセスが拒否されました` と出る場合は、保存先フォルダの書き込み権限が原因です。上記のとおり `$env:TEMP` に保存すれば回避できます（管理者権限は不要）。

次に、クリーンアップを実行する。

> **注意:** ダウンロードフォルダを **VSCode で開いている**とファイルがロックされて削除できません。先に **File → Close Folder** してから実行してください。

```powershell
# 実行（確認プロンプトが出るので y で開始。確認のみは末尾に -Check を付ける）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1"
```

実行中、`y` の入力を2回求められる（「開始」と「ダウンロードフォルダ削除」）。いずれも `y` で進めると、概要の表の内容（ブラウザ・メモ帳・Zoom の終了とデータ削除、ダウンロード／スクリーンショット削除、ごみ箱の空化）が実行され、続けて**確認（点検）が自動で実行される**。

> **注意:** ダウンロードフォルダの中身・`ピクチャ\Screenshots`・ブラウザ/メモ帳の未保存内容は削除されます。残したいものは事前に保存・退避してください。

> 各項目に `[OK]` が表示されていればクリーンアップ完了。`[NG]` の場合は該当ステップを見直すこと。

> **補足:** 後から点検し直したい場合は `powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1" -Check`（read-only。何度でも安全）。済んだら `Remove-Item "$env:TEMP\cleanup.ps1"` で後片付けする。

##### デスクトップ・ドキュメントの余分なファイル確認

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

---

#### B. 手動で1つずつ

PowerShell で上から順に実行する。

```powershell
# 1. ブラウザ・メモ帳・Zoom を終了する（未保存内容ごと閉じる）
Get-Process chrome, msedge, notepad, Zoom -ErrorAction SilentlyContinue | Stop-Process -Force
```

```powershell
# 2. ブラウザ（Chrome・Edge）の Cookie・履歴・ブックマーク・タブ/セッションを削除
$targets = 'Network\Cookies','Cookies','History','Bookmarks','Bookmarks.bak',
           'Current Session','Current Tabs','Last Session','Last Tabs','Sessions','Top Sites','Visited Links'
"$env:LOCALAPPDATA\Google\Chrome\User Data\Default", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" | ForEach-Object {
  $prof = $_
  $targets | ForEach-Object { Remove-Item (Join-Path $prof $_) -Recurse -Force -ErrorAction SilentlyContinue }
}
```

```powershell
# 3. メモ帳の未保存タブを削除
Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState\TabState\*" -Recurse -Force -ErrorAction SilentlyContinue
```

```powershell
# 4. Zoom のログイン情報を削除（次回起動時に再ログインが必要＝ログアウト状態になる）
Remove-Item "$env:APPDATA\Zoom\data" -Recurse -Force -ErrorAction SilentlyContinue
```

```powershell
# 5. ダウンロードフォルダの中身を全削除（desktop.ini は除く）
Get-ChildItem "$env:USERPROFILE\Downloads" -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force
```

```powershell
# 6. ピクチャのスクリーンショットを削除（Snipping Tool の自動保存・Win+PrtScn の保存先。desktop.ini は除く）
$shots = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Screenshots'
if (Test-Path $shots) { Get-ChildItem $shots -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
```

```powershell
# 7. ごみ箱を空にする
Clear-RecycleBin -Force
```

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
