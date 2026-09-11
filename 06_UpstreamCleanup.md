# 開発環境クリーンアップ手順（上流工程研修）

## 概要

研修終了後、PC を**セットアップ完了後の状態**（[04_UpstreamSetup.md](04_UpstreamSetup.md) を終えた直後の状態。ツール類はそのまま、認証・研修データは無し）に戻す手順です。

> **対象:** 上流工程研修用の PC を回収する運営担当者。下流工程研修・AI駆動開発研修の PC は [03_DevEnvironmentCleanup.md](03_DevEnvironmentCleanup.md) を参照してください。

上流工程研修の PC には WSL も VSCode も入っていないため、**Windows 側だけ**を対象にします。作業は **上流固有分** と **共通分** の2段階です。

| | クリーンアップ内容 | 使うスクリプト |
|---|---|---|
| **上流固有分** | Claude デスクトップアプリのサインイン情報・キャッシュ ／ Claude Code の設定・会話履歴 ／ 配布フォルダと受講者が作ったファイル ／ Git Bash の個人痕跡（`.bash_history`・`.gitconfig`・`.git-credentials`）／ LibreOffice のユーザープロファイル（最近使ったドキュメントを含む）／ Python・Node.js のキャッシュと対話履歴 ／ Windows のファイル履歴（最近使ったドキュメント・開く/保存ダイアログ） | `cleanup-upstream.ps1` |
| **共通分** | ブラウザ（Chrome・Edge）の Cookie・閲覧履歴・ブックマーク・タブ/セッション削除 ／ メモ帳の未保存タブ削除 ／ Zoom のログイン情報削除 ／ Teams・Outlook のログイン情報削除（新しい版・従来版の両方）／ Office のサインイン解除 ／ Windows 資格情報・「職場または学校アカウント」の削除 ／ サインイン共通キャッシュ（OneAuth・TokenBroker）の削除 ／ ダウンロードフォルダの全削除 ／ ピクチャのスクリーンショット削除 ／ エクスプローラー履歴の削除 ／ C:\ 直下の非標準フォルダの確認・削除 ／ ごみ箱を空にする | `cleanup.ps1`（下流工程研修と共通のもの） |

> **残すもの:** Git for Windows・Python とライブラリ3種・Node.js・LibreOffice・Claude デスクトップアプリの**本体は削除しません**（環境は変更しません）。消すのは認証情報・履歴・研修データだけです。

---

## クリーンアップ

### 1. Claude・ブラウザ・Zoom・Teams・Outlook の手動ログアウト

スクリプトでローカルの認証データを消す前に、各サービスでログアウトしておくとサーバー側セッションも無効化されます。

1. ブラウザで https://claude.ai を開き、左下のユーザーアイコン → **「Log out」**
2. Claude デスクトップアプリを起動し、サインアウトする（アプリ内のアカウント設定から）
3. Zoom デスクトップアプリを起動し、右上のプロフィールアイコン → **「サインアウト」**
4. Teams を起動し、右上のプロフィールアイコン → **「サインアウト」**
5. Outlook を起動し、アカウント設定から使用中のアカウントを**削除**する
   - 新しい Outlook: 右上の **設定（歯車）** → **アカウント** → 該当アカウント → **管理** → **削除**
   - 従来版 Outlook: **ファイル** → **アカウント設定** → **アカウント設定** → 該当アカウント → **削除**

> Zoom・Teams・Outlook を使っていなければ 3〜5 は不要です。使ったかどうか分からない場合は、先に共通分の確認（手順3 の `cleanup.ps1 -Check`）を実行するとログイン情報の有無が分かります。

---

### 2. 上流固有分のクリーンアップ

**受講者がサインインしていた Windows アカウント**でサインインし、スタートメニューで **「PowerShell」** を検索して、結果の中の **「Windows PowerShell」** を起動します（**管理者として実行はしません**）。

> **重要:** 削除対象は受講者のユーザープロファイル配下です。管理者として実行して別のアカウントの資格情報を入力すると、そちらのプロファイルを見てしまい、**何も消えていないのに確認がすべて `[OK]` になります**。
>
> **注意:** 検索結果には「Windows PowerShell ISE」も並びますが、**ISE は選ばないでください**（1件ずつの `y/N` 確認で止まることがあります）。

以下の **A**（スクリプトで一括）または **B**（手動で1つずつ）のどちらかを実施します。**A を推奨**します。

#### ✅ A. スクリプトで一括（推奨）

##### A-1. 実行（クリーンアップ＋自動確認）

```powershell
# ダウンロード（TEMP に保存。作業フォルダの権限に依存しない）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup-upstream.ps1 -OutFile "$env:TEMP\cleanup-upstream.ps1"
```

> **補足:** `アクセスが拒否されました` と出る場合は、保存先フォルダの書き込み権限が原因です。`$env:TEMP` に保存すれば回避できます。

```powershell
# 実行（確認プロンプトが出るので y で開始。確認のみは末尾に -Check を付ける）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup-upstream.ps1"
```

実行すると `y` の入力を求められます（「開始」、および**デスクトップ・ユーザーフォルダ直下に見つかった項目ごとに1件ずつ**）。`y` で進めると概要の表の「上流固有分」が実行され、続けて**確認が自動で実行される**。

> **アプリの終了:** Claude デスクトップアプリ・LibreOffice・Git Bash が起動しているとファイルを掴んで削除できないため、**スクリプトが自動で終了させます**（未保存の内容は失われます）。「削除に失敗しました」と出た場合は、該当アプリを閉じてから再実行してください。

> **配布フォルダ:** 名前が固定ではないため、デスクトップとユーザーフォルダ直下にある項目を**1件ずつ名前を確認して** `y/N` で削除します。確認（`-Check`）では削除せず `[情報]` として列挙するだけです。受講者が作った要件定義書・画面設計書もここに含まれるので、消し残しがないか一覧を必ず目で見てください。

> **LibreOffice のユーザープロファイル:** `%APPDATA%\LibreOffice` を削除します。最近使ったドキュメントの一覧（ファイル名とパス）がここに残るためです。次回起動時に初期状態で作り直されます。

##### A-2. 後片付け

確認まで終わったら、ダウンロードしたスクリプトを削除します（後から再確認する場合は、先に `-Check` を実行してから削除してください）。

```powershell
# 後片付け
Remove-Item "$env:TEMP\cleanup-upstream.ps1" -ErrorAction SilentlyContinue
```

#### 🔧 B. 手動で1つずつ

PowerShell で上から順に実行します。

##### B-1. アプリの終了

```powershell
# ファイルを掴んでいるアプリを終了する（未保存の内容ごと閉じる）
# OneDrive は同期でファイルを掴むため一緒に終了する（次回サインイン時に自動起動する）
Get-Process claude, soffice, soffice.bin, bash, mintty, OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
```

##### B-2. Claude デスクトップアプリのサインイン情報・キャッシュ削除

```powershell
# サインイン情報・キャッシュを削除（次回起動時にサインイン画面から始まる）
# ※ %LOCALAPPDATA%\AnthropicClaude と %LOCALAPPDATA%\Claude はアプリ本体の置き場でもあるため、
#    ツリーごとではなくデータ用のサブフォルダだけを消す。
Remove-Item "$env:APPDATA\Claude" -Recurse -Force -ErrorAction SilentlyContinue
foreach ($root in @("$env:LOCALAPPDATA\AnthropicClaude", "$env:LOCALAPPDATA\Claude")) { foreach ($sub in @('Cache','Code Cache','GPUCache','DawnCache','Local Storage','Session Storage','IndexedDB','Network','Cookies','Partitions','Crashpad','logs','Service Worker','blob_storage','databases','sentry')) { Remove-Item -LiteralPath (Join-Path $root $sub) -Recurse -Force -ErrorAction SilentlyContinue } }
```

##### B-3. Claude Code の設定・会話履歴削除

```powershell
# Code タブで行った会話・プロジェクト履歴を削除（.backup にも同じ内容が残る）
Remove-Item "$env:USERPROFILE\.claude", "$env:USERPROFILE\.claude.json", "$env:USERPROFILE\.claude.json.backup" -Recurse -Force -ErrorAction SilentlyContinue
```

##### B-4. Git Bash の個人痕跡削除

```powershell
# コマンド履歴と git の設定（氏名・メールアドレス）・保存された認証情報を削除
Remove-Item "$env:USERPROFILE\.bash_history", "$env:USERPROFILE\.gitconfig", "$env:USERPROFILE\.git-credentials" -Force -ErrorAction SilentlyContinue
```

##### B-5. LibreOffice のユーザープロファイル削除

```powershell
# 最近使ったドキュメントの一覧を含むユーザープロファイルを削除（次回起動時に作り直される）
Remove-Item "$env:APPDATA\LibreOffice" -Recurse -Force -ErrorAction SilentlyContinue
```

##### B-6. Python・Node.js のキャッシュと対話履歴の削除

```powershell
# pip・npm のキャッシュと、対話実行の履歴を削除
Remove-Item "$env:LOCALAPPDATA\pip\Cache", "$env:LOCALAPPDATA\npm-cache", "$env:APPDATA\npm-cache", "$env:USERPROFILE\.python_history", "$env:USERPROFILE\.node_repl_history" -Recurse -Force -ErrorAction SilentlyContinue
```

##### B-7. Windows のファイル履歴の削除

LibreOffice 側の履歴を消しても、Windows 側に成果物のファイル名とパスが残ります。

```powershell
# 最近使ったドキュメントと、開く/保存ダイアログの履歴を削除
Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU' -Recurse -Force -ErrorAction SilentlyContinue
```

##### B-8. 配布フォルダ・研修で作られたファイルの削除

まず、デスクトップとユーザーフォルダ直下にある項目を一覧表示します。

```powershell
# 一覧表示（削除はしない）
Get-ChildItem ([Environment]::GetFolderPath('Desktop')), $env:USERPROFILE -Force -ErrorAction SilentlyContinue | Select-Object FullName
```

配布フォルダや受講者が作ったファイルがあれば、名前を確認してから削除します（`<名前>` を一覧に出た実際の名前に置き換えてください）。

```powershell
# デスクトップの項目を削除
Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('Desktop')) "<名前>") -Recurse -Force
```

```powershell
# ユーザーフォルダ直下の項目を削除
Remove-Item -LiteralPath (Join-Path $env:USERPROFILE "<名前>") -Recurse -Force
```

> **注意:** `-Recurse -Force` は確認なしで削除します。`<名前>` が一覧に表示されたものと一致しているか確認してから実行してください。ユーザーフォルダ直下には `Documents`・`Downloads` などの標準フォルダや、**`OneDrive - <会社名>`（会社の同期フォルダ）** も並びます。**これらは絶対に消さないでください**（OneDrive を消すとクラウド側からも消えます）。

##### B-9. 点検（手動）

削除後、こちらで点検します（各項目に OK/NG が表示されます）。

```powershell
# 確認（手動。スクリプトを使わず点検する）
if (Test-Path -LiteralPath "$env:APPDATA\Claude") { "NG: Claude アプリのデータ残存 ($env:APPDATA\Claude)" } else { "OK: Claude アプリのデータなし" }
foreach ($p in @("$env:USERPROFILE\.claude", "$env:USERPROFILE\.claude.json", "$env:USERPROFILE\.claude.json.backup")) { if (Test-Path -LiteralPath $p) { "NG: Claude Code の履歴残存 ($p)" } else { "OK: Claude Code の履歴なし ($p)" } }
foreach ($p in @("$env:USERPROFILE\.bash_history", "$env:USERPROFILE\.gitconfig", "$env:USERPROFILE\.git-credentials")) { if (Test-Path -LiteralPath $p) { "NG: Git Bash の痕跡残存 ($p)" } else { "OK: Git Bash の痕跡なし ($p)" } }
if (Test-Path -LiteralPath "$env:APPDATA\LibreOffice") { "NG: LibreOffice のプロファイル残存" } else { "OK: LibreOffice のプロファイルなし" }
foreach ($p in @("$env:LOCALAPPDATA\pip\Cache", "$env:LOCALAPPDATA\npm-cache", "$env:APPDATA\npm-cache")) { if (Test-Path -LiteralPath $p) { "NG: キャッシュ残存 ($p)" } else { "OK: キャッシュなし ($p)" } }
foreach ($k in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU')) { if (Test-Path -LiteralPath $k) { "NG: Windows のファイル履歴残存 ($k)" } else { "OK: Windows のファイル履歴なし ($k)" } }
if (cmdkey /list 2>$null | Select-String -Pattern 'Claude' -SimpleMatch) { "NG: Windows 資格情報に Claude 名義あり（資格情報マネージャーから削除）" } else { "OK: Windows 資格情報に Claude 名義なし" }
```

一覧を目で見る分も確認します。

```powershell
# デスクトップ・ユーザーフォルダ直下・ドキュメント・ピクチャ（研修の残りが無いか目視）
Get-ChildItem ([Environment]::GetFolderPath('Desktop')), $env:USERPROFILE, ([Environment]::GetFolderPath('MyDocuments')), ([Environment]::GetFolderPath('MyPictures')) -Force -ErrorAction SilentlyContinue | Select-Object FullName
```

> ツール本体（Git・Python・Node.js・LibreOffice・Claude デスクトップアプリ）が**残っている**ことも確認します。消してしまっていないかの確認です。

```powershell
# ツールが残っているか（すべて OK と表示されること）
foreach ($c in @('git','python','node')) { if (Get-Command $c -CommandType Application -ErrorAction SilentlyContinue) { "OK: $c あり" } else { "NG: $c が見つかりません" } }
if (@("$env:ProgramFiles\LibreOffice\program\soffice.exe", "${env:ProgramFiles(x86)}\LibreOffice\program\soffice.exe") | Where-Object { $_ -and (Test-Path -LiteralPath $_) }) { "OK: LibreOffice あり" } else { "NG: LibreOffice が見つかりません" }
if (@("$env:LOCALAPPDATA\AnthropicClaude\claude.exe", "$env:LOCALAPPDATA\Programs\Claude\Claude.exe", "$env:ProgramFiles\Claude\Claude.exe") | Where-Object { Test-Path -LiteralPath $_ }) { "OK: Claude デスクトップアプリあり" } else { "NG: Claude デスクトップアプリの実行ファイルが見つかりません" }
```

---

### 3. 共通分のクリーンアップ

ブラウザ・Zoom・Teams・Outlook・Office・資格情報・ダウンロード・ごみ箱は、下流工程研修と共通の `cleanup.ps1` で実施します。

```powershell
# ダウンロード（TEMP に保存）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.ps1 -OutFile "$env:TEMP\cleanup.ps1"
```

```powershell
# 実行（確認プロンプトが出るので y で開始。確認のみは末尾に -Check を付ける）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1"
```

> **注意:** `cleanup.ps1` は WSL や VSCode を対象にしていないため、上流工程研修の PC でもそのまま実行できます。**手順2 より先に実行しないでください**。`cleanup.ps1` は最後にごみ箱を空にするので、先に実行すると、そのあと手順2 でエクスプローラーから削除したファイルがごみ箱に残ったまま返却されます。

> 実行内容と出てくる確認（`C:\` 直下の非標準フォルダ、デスクトップ・ドキュメント・ピクチャの一覧など）の詳しい説明は [03_DevEnvironmentCleanup.md](03_DevEnvironmentCleanup.md) の「4. Windows側のクリーンアップ」と同じです。

```powershell
# 後片付け
Remove-Item "$env:TEMP\cleanup.ps1" -ErrorAction SilentlyContinue
```

---

### 4. 成果物の残りの確認

受講者は LibreOffice で要件定義書・画面設計書・スライドを開いて保存します。既定の保存先はドキュメントになることがあるため、デスクトップ以外も見ます。

`cleanup.ps1` の確認出力には、**デスクトップ／ドキュメント／ピクチャ**の一覧が `[情報]` として表示されます（合否判定はしません）。研修で作られたファイルがあれば削除します（`<名前>` を一覧に出た実際の名前に置き換えてください）。

```powershell
# ドキュメントの項目を削除
Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('MyDocuments')) "<名前>") -Recurse -Force
```

```powershell
# ピクチャの項目を削除
Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('MyPictures')) "<名前>") -Recurse -Force
```

> **OneDrive と同期している場合:** ドキュメントやデスクトップが OneDrive の同期対象になっていると、成果物が会社の OneDrive にも残ります。ローカルの削除が同期先へ伝わったか、OneDrive のごみ箱に残っていないかを、ブラウザで OneDrive を開いて確認してください。

ここで削除を行った場合は、ごみ箱を空にします。

```powershell
# ごみ箱を空にする
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
```

---

### 5. 最終確認

1. Claude デスクトップアプリを起動し、**サインイン画面から始まる**ことを確認する（前の受講者のメールアドレスが候補に出ないこと）。確認したら終了する
2. デスクトップ・ユーザーフォルダ直下・ドキュメント・ピクチャに、配布フォルダや受講者が作ったファイルが残っていないことを確認する
3. スタートメニューから Git Bash を起動し、`git --version`・`python --version`・`node -v` が表示されることを確認する（ツール本体は残す）

> **1 でアカウントの候補が表示される場合**は、Claude デスクトップアプリのデータが消えていません。手順2 の B-2・B-3（`%APPDATA%\Claude` とユーザーフォルダ直下の `.claude` 系）をやり直してください。共通分の OneAuth・TokenBroker は Microsoft のサインイン基盤なので、ここには関係しません。

> **確認のあとに点検し直すと `[NG]` が出ます:** 1 で Claude デスクトップアプリを起動するとデータのフォルダが作り直され、3 で Git Bash を閉じると `.bash_history` が作り直されます。確認のあとに `cleanup-upstream.ps1 -Check` を実行して `[NG]` が出た場合は、**この確認操作による作り直し**か、消し漏れかを見分けてください。厳密に空の状態で返すなら、最終確認のあとに手順2 をもう一度実行します。

---

### 6. Claude Team ワークスペースの後始末

PC のクリーンアップとは別に、**Claude の Team ワークスペースから受講者のアカウントを削除**します（管理コンソールから行います）。ここを残すと、返却後も受講者が研修用のワークスペースにアクセスできます。
