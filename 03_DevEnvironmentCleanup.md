# 開発環境クリーンアップ手順

## 概要

研修終了後、PC を**セットアップ完了後の状態**（ツール類はそのまま、認証・研修データは無し）に戻す手順です。
**WSL側** と **Windows側** の2部構成で実施します。

| | クリーンアップ内容 |
|---|---|
| **WSL側** | Claude Code 認証解除 ／ GitHub CLI 認証解除（下流工程研修のみ）／ Claude Code 履歴削除 ／ git・bash の個人痕跡削除 ／ 研修資料削除 ／ VSCode の標準外拡張機能の確認・削除 |
| **Windows側** | ブラウザ（Chrome・Edge）の Cookie・閲覧履歴・ブックマーク・タブ/セッション削除 ／ メモ帳の未保存タブ削除 ／ Zoom のログイン情報削除 ／ ダウンロードフォルダの全削除 ／ ごみ箱を空にする |

> **残すもの:** WSL/Ubuntu 本体、VSCode、`gh`・`claude`・JDK・Maven などのツール類と環境変数は削除しません（環境は変更しません）。

> **注意:** **この手順書を Chrome／Edge で開いている場合は、VSCode の Markdown プレビューや別端末（スマホ等）で開き直してください。** クリーンアップ対象のブラウザで手順を読み続けると、手順4 で履歴を消した後も再表示のたびに閲覧履歴が再生成され、`cleanup.ps1 -Check` でそのブラウザの履歴だけ `[NG]` になります。クリーンアップ以降はそのブラウザを開かないのが確実です。

---

## クリーンアップ

### 1. ブラウザ・Zoom の手動ログアウト（先に実施）

スクリプトでローカルの認証データを削除する前に、各サービスで明示的にログアウトしておくとサーバー側セッションも無効化され確実です。

1. ブラウザで https://claude.ai を開き、左下のユーザーアイコン → **「Log out」**
2. （**下流工程研修のみ**）https://github.com を開き、右上のアイコン → **「Sign out」**
3. Zoom デスクトップアプリを起動し、右上のプロフィールアイコン → **「サインアウト」**

---

### 2. WSL側のクリーンアップ

VSCode のメニューバー → **Terminal** → **New Terminal**（または `Ctrl+@`）で VSCode 内のターミナルを開き、以下を実行する。

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.sh -o cleanup.sh
```

```bash
# 実行（確認プロンプトが出るので y で開始。確認のみは bash cleanup.sh --check）
bash cleanup.sh
```

> **注意:** 後片付け（`rm cleanup.sh`）は、次の確認まで終えてから行う（確認も同じ `cleanup.sh` を使うため）。

実行すると、まず**「クリーンアップを実行しますか？」と確認される**ので `y` で開始する。続いて認証解除・履歴削除などが進んだあと、ホーム直下のファイル・フォルダ一覧（隠しファイルを除く）が表示され、削除する研修資料の名前（ファイル/フォルダ可）の入力を求められるので入力する。**研修資料が複数のファイル・フォルダに分かれている場合は、一覧→入力→削除を繰り返せる**（削除し終えたら空欄のまま Enter で終了）。

> **補足:** 研修資料が無い／既に削除済みの場合も、**空欄のまま Enter** で終了できる（無くても処理は止まらない）。
> **補足:** bash 履歴を完全に消すため、作業後はこのターミナルを閉じてください。

#### cleanup.sh --check でクリーンアップ確認

```bash
# 確認（--check は確認のみ。削除は行わない）
bash cleanup.sh --check
```

```bash
# 後片付け
rm cleanup.sh
```

> この確認では、**【1】個人データが消えたか**（認証・履歴・git・研修資料・拡張機能）と、**【2】開発環境が残っているか**（gh／claude／JDK／Maven 等のツール）の両方を点検する。**【1】がすべて `[OK]`／`[--]`、【2】がすべて `[OK]`** であれば、次の研修生に渡せる状態（セットアップ完了状態）。`[NG]` の場合は該当ステップを見直すこと。

> **VSCode 拡張機能について:** この確認は、セットアップ標準セット（WSL／Java／Spring Boot ／ Office Viewer とその関連）**以外**の拡張機能を検出して一覧表示する（研修生が追加した拡張の検出）。`[NG]` で拡張機能IDが表示された場合は、研修に不要なものか確認のうえ、以下で削除する。削除後にもう一度 `bash cleanup.sh --check` を実行すると消えたか確認できる。
> ```bash
> code --uninstall-extension <拡張機能ID>
> ```
> ※ この確認は **VSCode 内の WSL ターミナル**で実行する必要がある（`code` コマンドが使えるため）。`code` が見つからない場合は `[--]` と表示される。

#### 手動で実施する場合

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

# 5. 研修資料の削除（ファイル/フォルダ。複数あれば繰り返す）
rm -rf ~/（研修資料の名前）
```

削除後、スクリプトが使えない場合はこちらで点検する（各項目に OK/NG が表示される）。

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

まず、**スクリプトをダウンロード**しておく。先に取得しておけば、クリーンアップ後にブラウザを開き直してスクリプトを取りに行く必要がなくなる（手順書を Chrome で見ている場合に、履歴が再生成されて確認で `[NG]` になる問題を避けられる）。実行も確認も同じ `cleanup.ps1` を使う（確認は `-Check` を付ける）。

```powershell
# ダウンロード（TEMP に保存。作業フォルダの権限に依存しない）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.ps1 -OutFile "$env:TEMP\cleanup.ps1"
```

> **補足:** `アクセスが拒否されました` と出る場合は、保存先フォルダの書き込み権限が原因です。上記のとおり `$env:TEMP` に保存すれば回避できます（管理者権限は不要）。

次に、クリーンアップを実行する。

```powershell
# 実行（確認プロンプトが出るので y で開始。確認のみは末尾に -Check を付ける）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1"
```

実行すると、まず**「クリーンアップを実行しますか？」と確認される**ので `y` で開始する。続いてブラウザ（Chrome・Edge）・メモ帳・Zoom が終了され、ブラウザの Cookie・閲覧履歴・ブックマーク・タブ/セッション（最近閉じたタブ等）とメモ帳の未保存タブ、Zoom のログイン情報が削除される（Zoom は次回起動時に再ログインが必要な状態になる）。さらに**ダウンロードフォルダの全削除確認**を求められるので、ここでも `y` で実行する（`y` を打つのは「開始」と「ダウンロード削除」の計2回）。最後にごみ箱が空になる。

> **注意:** ダウンロードフォルダは**中身がすべて削除**されます。残したいファイルがある場合は事前に退避してください。
> **注意:** ブラウザとメモ帳は自動で終了されます。**未保存の内容は破棄されます**ので、残したい作業がある場合は事前に保存してください。
> **注意:** ダウンロードフォルダ内のフォルダを **VSCode で開いている**（ワークスペースにしている）と、ファイルがロックされて削除できず残ります。`cleanup.ps1` は VSCode を終了させないため、**先に VSCode で File → Close Folder（またはVSCodeを閉じる）してから**実行してください。研修資料を誤って WSL ではなくダウンロード内に展開・配置したケースで起こりやすいです。

#### cleanup.ps1 -Check でクリーンアップ確認

クリーンアップが終わったら、**先にダウンロードしておいた**スクリプトを `-Check` 付きで実行する（ブラウザを開き直さずに済む）。

```powershell
# 確認（-Check は確認のみ。削除は行わない）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1" -Check
```

> 各項目に `[OK]` が表示されていればクリーンアップ完了。`[NG]` の場合は該当ステップを見直すこと。

```powershell
# 後片付け
Remove-Item "$env:TEMP\cleanup.ps1" -ErrorAction SilentlyContinue
```

#### デスクトップ・ドキュメントの余分なファイル確認

上記の `cleanup.ps1 -Check` の出力に、**デスクトップ／ドキュメント**にあるファイル・フォルダ一覧が `[情報]` として表示される（合否判定はしない）。`Visual Studio Code` などセットアップ手順で作られたもの以外（研修生が作成したファイル・ショートカット等）があれば削除する。

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

#### 手動で実施する場合

PowerShell で以下を実行する。

```powershell
# 1. ブラウザ・メモ帳・Zoom を終了する（未保存内容ごと閉じる）
Get-Process chrome, msedge, notepad, Zoom -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. ブラウザ（Chrome・Edge）の Cookie・履歴・ブックマーク・タブ/セッションを削除
$targets = 'Network\Cookies','Cookies','History','Bookmarks','Bookmarks.bak',
           'Current Session','Current Tabs','Last Session','Last Tabs','Sessions','Top Sites','Visited Links'
"$env:LOCALAPPDATA\Google\Chrome\User Data\Default", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" | ForEach-Object {
  $prof = $_
  $targets | ForEach-Object { Remove-Item (Join-Path $prof $_) -Recurse -Force -ErrorAction SilentlyContinue }
}

# 3. メモ帳の未保存タブを削除
Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState\TabState\*" -Recurse -Force -ErrorAction SilentlyContinue

# 4. Zoom のログイン情報を削除（次回起動時に再ログインが必要＝ログアウト状態になる）
Remove-Item "$env:APPDATA\Zoom\data" -Recurse -Force -ErrorAction SilentlyContinue

# 5. ダウンロードフォルダの中身を全削除（desktop.ini は除く）
Get-ChildItem "$env:USERPROFILE\Downloads" -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force

# 6. ごみ箱を空にする
Clear-RecycleBin -Force
```

削除後、スクリプトが使えない場合はこちらで点検する（各項目に OK/NG が表示される）。

```powershell
# 確認（手動。スクリプトを使わず点検する）
$dl = (Get-ChildItem "$env:USERPROFILE\Downloads" -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' }).Count
if ($dl -eq 0) { Write-Host "OK: ダウンロードフォルダ 空" } else { Write-Host "NG: ダウンロード $dl 件残存" }
if (Test-Path "$env:APPDATA\Zoom\data") { Write-Host "NG: Zoom ログイン情報 残存" } else { Write-Host "OK: Zoom ログインなし" }
foreach ($p in @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History")) {
  if (Test-Path $p) { Write-Host "NG: ブラウザ履歴 残存 ($p)" } else { Write-Host "OK: ブラウザ履歴なし ($p)" }
}
```
