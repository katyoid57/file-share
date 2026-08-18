# 開発環境クリーンアップ手順

## 概要

研修終了後、PC を**セットアップ完了後の状態**（ツール類はそのまま、認証・研修データは無し）に戻す手順です。
**WSL側** と **Windows側** の2部構成で実施します。

| | クリーンアップ内容 |
|---|---|
| **WSL側** | Claude Code 認証解除 ／ GitHub CLI 認証解除（下流工程研修のみ）／ Claude Code 履歴削除 ／ git・bash の個人痕跡削除 ／ 研修資料の一括削除（ホーム直下の `setup.sh`・`cleanup.sh` 以外）／ 見慣れない隠し項目の参考表示 ／ VSCode の標準外拡張機能の確認・削除 |
| **Windows側** | ブラウザ（Chrome・Edge）の Cookie・閲覧履歴・ブックマーク・タブ/セッション削除 ／ メモ帳の未保存タブ削除 ／ Zoom のログイン情報削除 ／ **Teams・Outlook のログイン情報削除（新しい版・従来版の両方）** ／ **Office のサインイン解除** ／ **Windows 資格情報・「職場または学校アカウント」の削除** ／ **サインイン共通キャッシュ（OneAuth・TokenBroker）の削除** ／ ダウンロードフォルダの全削除 ／ ピクチャのスクリーンショット削除 ／ エクスプローラー履歴（最近使ったファイル・クイックアクセス・検索/アドレスバー）削除 ／ C:\ 直下の非標準フォルダの確認・削除 ／ ごみ箱を空にする |

> **残すもの:** WSL/Ubuntu 本体、VSCode、`gh`・`claude`・JDK・Maven などのツール類と環境変数は削除しません（環境は変更しません）。

---

## クリーンアップ

### 1. ブラウザ・Zoom・Teams・Outlook の手動ログアウト

スクリプトでローカルの認証データを消す前に、各サービスでログアウトしておくとサーバー側セッションも無効化されます。

1. ブラウザで https://claude.ai を開き、左下のユーザーアイコン → **「Log out」**
2. Zoom デスクトップアプリを起動し、右上のプロフィールアイコン → **「サインアウト」**
3. Teams を起動し、右上のプロフィールアイコン → **「サインアウト」**
4. Outlook を起動し、アカウント設定から使用中のアカウントを**削除**する
   - 新しい Outlook: 右上の **設定（歯車）** → **アカウント** → 該当アカウント → **管理** → **削除**
   - 従来版 Outlook: **ファイル** → **アカウント設定** → **アカウント設定** → 該当アカウント → **削除**

> Teams・Outlook を使っていなければ 3・4 は不要です。使ったかどうか分からない場合は、先にクリーンアップスクリプトの確認（`-Check`）を実行するとログイン情報の有無が分かります。

---

### 2. WSL側のクリーンアップ

以下の **A**（スクリプトで一括）または **B**（手動で1つずつ）のどちらかを実施する。**A を推奨**する。

#### ✅ A. スクリプトで一括（推奨）

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

確認に `y` で答えると認証解除・履歴削除が進み、**研修資料の削除**では、ホーム直下の項目のうち `setup.sh`・`cleanup.sh` **以外**の非隠し項目が削除対象として一覧表示される。`y` で答えると**まとめて削除**する（1つずつ名前を入力する必要はない）。あわせて、標準の開発環境ファイル以外の**見慣れない隠し項目**があれば参考として一覧表示される（こちらは自動削除しないので、中身を確認して不要なら手動で削除する）。続いて、標準セット外の VSCode 拡張があれば一覧表示されるので、`y` でまとめてアンインストールできる。

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

#### 🔧 B. 手動で1つずつ

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

#### ✅ A. スクリプトで一括（推奨）

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

実行すると `y` の入力を求められる（「開始」「ダウンロードフォルダ削除」、および **C:\ 直下に非標準フォルダがあればフォルダごとに1件ずつ**）。`y` で進めると、概要の表の内容（ブラウザ・メモ帳・Zoom・Teams・Outlook の終了とデータ削除、Office のサインイン解除、Windows 資格情報・職場アカウント・サインイン共通キャッシュの削除、ダウンロード／スクリーンショット削除、エクスプローラー履歴削除、C:\ 直下の非標準フォルダ削除、ごみ箱の空化）が実行され、続けて**確認（点検）が自動で実行される**。

> **C:\ 直下の非標準フォルダ:** 標準フォルダ（Windows／Program Files／Users 等）以外が `C:\` 直下にあれば、研修生が作成した可能性があるものとして**1件ずつ名前を確認して** `y/N` で削除できる。確認（`-Check`）では削除せず `[情報]` として列挙するだけ。
> ※ `C:\` 直下のフォルダ削除は**管理者権限が必要**な場合がある。「削除に失敗しました」と出たら、PowerShell を**管理者として実行**して再度クリーンアップを実行する。
> **エクスプローラー履歴:** 最近使ったファイル・クイックアクセス・検索/アドレスバー入力履歴を削除する。履歴ファイルはエクスプローラーがロックしているため、**スクリプトが自動でエクスプローラーを一旦終了してから削除する**（タスクバー/デスクトップが数秒消えるが、Windows が自動で復帰させる。戻らない場合はサインアウト/再起動）。

> **Teams・Outlook:** 「新しい Teams / 新しい Outlook」（Windows アプリ版）と「従来版」でログイン情報の置き場所が違うため、**両方を対象に削除する**（インストールされていない方は自動でスキップされる）。従来版 Outlook では、アカウント設定（レジストリのプロファイル）と受信メールのキャッシュ（`.ost`）・署名もあわせて削除される。削除後は次回起動時にサインイン画面から始まる。
> ※ アプリが起動中だとファイルがロックされて削除できないため、スクリプトが**自動で Teams・Outlook を終了してから**削除する。「削除に失敗しました」と出た場合は、アプリを閉じてから再実行する。

> **Windows 資格情報・職場または学校アカウント:** アプリのデータを消しても、Windows 側にアカウントとトークンが残っていると次回起動時に**再入力なしでサインインできてしまう**ため、Teams/Outlook/Office 関連の資格情報と、サインイン中ユーザーの職場アカウント情報も削除する。
> ※ 削除されるのは**サインイン中ユーザーのトークンキャッシュ**だけで、PC 自体のドメイン参加・Azure AD 参加は解除されない。
> ※ 削除後も設定アプリの一覧に表示が残る場合は、**設定 → アカウント → メールとアカウント** から該当アカウントを「切断」する。

> **Office のサインイン:** Word・Excel などにも同じアカウントが残るため、サインイン情報を削除してサインアウト状態にする。Office が入っていなければスキップされる。
> ※ Office が**受講者のアカウントでライセンス認証されている**場合、サインアウトすると未ライセンス状態になる（次の受講者が自分のアカウントでサインインし直す想定）。

> **サインイン共通キャッシュ（OneAuth・TokenBroker）:** 新しい Teams の「ようこそ」画面に出る**アカウントの選択肢はここを読んでいる**ため、Teams のデータを消してもここが残っていると前の受講者のアカウントが一覧に出てしまう（パスワードは要求されるが、メールアドレスは見える状態）。
> ※ OneAuth は **OneDrive も共用**しているため、削除すると OneDrive もサインアウトする。また起動中はファイルがロックされるため、スクリプトが**自動で OneDrive を終了してから**削除する（次回サインイン時に自動起動する）。

> **確認のとき Teams を起動した場合:** Teams を起動すると `LocalCache` が作り直されるため、その後に `-Check` を実行すると Teams が `[NG]` と表示される。**ようこそ画面にアカウントの選択肢が出なければ問題ない**（ログイン情報そのものは消えている）。厳密に確認したい場合は、Teams を閉じてからクリーンアップを再実行する。

> **補足:** 後から点検し直したい場合は `powershell -ExecutionPolicy Bypass -File "$env:TEMP\cleanup.ps1" -Check`（read-only。何度でも安全）。

##### A-2. デスクトップ・ドキュメント・ピクチャの余分なファイル確認

確認（自動実行または `-Check`）の出力に、**デスクトップ／ドキュメント／ピクチャ**にあるファイル・フォルダ一覧が `[情報]` として表示される（合否判定はしない）。`Visual Studio Code` などセットアップ手順で作られたもの以外（研修生が作成したファイル・ショートカット等）があれば削除する。

削除する場合は、エクスプローラーで右クリック → 削除するか、PowerShell で以下を実行する（`<名前>` を一覧に出た実際の名前に置き換える）。

```powershell
# デスクトップのファイル/フォルダを削除
Remove-Item (Join-Path ([Environment]::GetFolderPath('Desktop')) "<名前>") -Recurse -Force
```

```powershell
# ドキュメントのファイル/フォルダを削除
Remove-Item (Join-Path ([Environment]::GetFolderPath('MyDocuments')) "<名前>") -Recurse -Force
```

```powershell
# ピクチャのファイル/フォルダを削除
Remove-Item (Join-Path ([Environment]::GetFolderPath('MyPictures')) "<名前>") -Recurse -Force
```

> **注意:** `-Recurse -Force` は確認なしで削除します。`<名前>` が一覧に表示されたものと一致しているか確認してから実行してください。
> 削除後にもう一度 `cleanup.ps1 -Check` を実行すると、消えたか確認できます。

##### A-3. 後片付け

確認まで終わったら、ダウンロードしたスクリプトを削除する（後から再確認する場合は、先に `-Check` を実行してから削除する）。

```powershell
# 後片付け
Remove-Item "$env:TEMP\cleanup.ps1" -ErrorAction SilentlyContinue
```

#### 🔧 B. 手動で1つずつ

PowerShell で上から順に実行する。

##### B-1. ブラウザ・メモ帳・Zoom・Teams・Outlook・OneDrive を終了

```powershell
# ブラウザ・メモ帳・Zoom・Teams・Outlook・OneDrive を終了する（未保存内容ごと閉じる）
# ms-teams=新しい Teams ／ Teams=従来版 Teams ／ olk=新しい Outlook ／ OUTLOOK=従来版 Outlook
# OneDrive はサインイン共通キャッシュ（B-10）を掴むため一緒に終了する（次回サインイン時に自動起動する）
Get-Process chrome, msedge, notepad, Zoom, ms-teams, Teams, olk, OUTLOOK, OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force
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

##### B-5. Teams のログイン情報削除

```powershell
# 新しい Teams（Windows アプリ版）のログイン情報・キャッシュを削除
Remove-Item "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache" -Recurse -Force -ErrorAction SilentlyContinue
# 従来版 Teams のログイン情報・キャッシュを削除
Remove-Item "$env:APPDATA\Microsoft\Teams" -Recurse -Force -ErrorAction SilentlyContinue
```

##### B-6. Outlook のログイン情報・プロファイル削除

```powershell
# 新しい Outlook（Windows アプリ版）のログイン情報・キャッシュを削除
Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe\LocalCache" -Recurse -Force -ErrorAction SilentlyContinue
# 従来版 Outlook のデータファイル（.ost＝受信メールのキャッシュ）・署名・送信設定を削除
Remove-Item "$env:LOCALAPPDATA\Microsoft\Outlook" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Microsoft\Outlook" -Recurse -Force -ErrorAction SilentlyContinue
```

```powershell
# 従来版 Outlook のプロファイル（メールアドレス・アカウント設定）を削除
# Office のバージョンキー（16.0 等）は環境によって複数残るため、まとめて対象にする
Get-ChildItem 'HKCU:\Software\Microsoft\Office' -ErrorAction SilentlyContinue |
  Where-Object { $_.PSChildName -match '^\d+\.\d+$' } | ForEach-Object {
    foreach ($sub in @('Outlook\Profiles', 'Outlook\AutoDiscover')) {
      Remove-Item "HKCU:\Software\Microsoft\Office\$($_.PSChildName)\$sub" -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
```

##### B-7. Office のサインイン情報削除

```powershell
# Office アプリ（Word/Excel 等）のサインイン情報を削除（Office 未インストールなら何も起きない）
Get-ChildItem 'HKCU:\Software\Microsoft\Office' -ErrorAction SilentlyContinue |
  Where-Object { $_.PSChildName -match '^\d+\.\d+$' } | ForEach-Object {
    Remove-Item "HKCU:\Software\Microsoft\Office\$($_.PSChildName)\Common\Identity" -Recurse -Force -ErrorAction SilentlyContinue
  }
```

> **注意:** Office が受講者のアカウントでライセンス認証されている場合、サインアウトすると未ライセンス状態になります（次の受講者が自分のアカウントでサインインし直す想定）。

##### B-8. Windows 資格情報の削除

```powershell
# 資格情報マネージャーから Teams/Outlook/Office 関連の資格情報を削除
cmdkey /list | Select-String -Pattern '(?:LegacyGeneric|Domain|WindowsLive|MicrosoftAccount):\S+' -AllMatches |
  ForEach-Object { $_.Matches.Value } |
  Where-Object { $_ -match 'MicrosoftOffice|Teams|Outlook' } |
  ForEach-Object {
    $t = $_ -replace '^[A-Za-z]+:target=', ''
    cmdkey /delete:$t
  }
```

> 残りは **コントロールパネル → ユーザーアカウント → 資格情報マネージャー** で確認・削除できます。

##### B-9. 職場または学校アカウントの削除

```powershell
# Windows「職場または学校アカウント」（設定 → アカウント → メールとアカウント）のサインイン情報を削除
Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts" -Force -ErrorAction SilentlyContinue |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
```

> 削除されるのは**サインイン中ユーザーのトークンキャッシュ**だけで、PC 自体のドメイン参加・Azure AD 参加は解除されません。
> 実行後も設定アプリの一覧に表示が残る場合は、**設定 → アカウント → メールとアカウント** から該当アカウントを「切断」してください。

##### B-10. サインイン共通キャッシュ（OneAuth・TokenBroker）の削除

```powershell
# 新しい Teams の「ようこそ」画面に出るアカウントの選択肢はここ（OneAuth）を読んでいる
# フォルダ自体は残し、中身だけ削除する（次回サインイン時に作り直される）
foreach ($p in @("$env:LOCALAPPDATA\Microsoft\OneAuth", "$env:LOCALAPPDATA\Microsoft\TokenBroker\Cache")) {
  Get-ChildItem $p -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
```

> OneAuth は **OneDrive も共用**しているため、削除すると OneDrive もサインアウトします。起動中はロックされて削除できないので、**B-1 で OneDrive を終了してから**実行してください。

##### B-11. ダウンロードフォルダを空にする

```powershell
# ダウンロードフォルダの中身を全削除（desktop.ini は除く）
Get-ChildItem "$env:USERPROFILE\Downloads" -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force
```

##### B-12. ピクチャのスクリーンショット削除

```powershell
# ピクチャのスクリーンショットを削除（Snipping Tool の自動保存・Win+PrtScn の保存先。desktop.ini は除く）
$shots = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Screenshots'
if (Test-Path $shots) { Get-ChildItem $shots -Force | Where-Object { $_.Name -ne 'desktop.ini' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
```

##### B-13. エクスプローラーの履歴削除

```powershell
# 履歴ファイルはエクスプローラーがロックするため、先にエクスプローラーを終了する
# （タスクバー/デスクトップが数秒消えるが、Windows が自動で復帰させる）
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 最近使ったファイル・クイックアクセス（ジャンプリスト）の中身を削除
$recent = "$env:APPDATA\Microsoft\Windows\Recent"
foreach ($sub in @('', 'AutomaticDestinations', 'CustomDestinations')) {
  $p = if ($sub) { Join-Path $recent $sub } else { $recent }
  if (Test-Path $p) { Get-ChildItem $p -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }
}
# 検索履歴（WordWheelQuery）・アドレスバー入力履歴（TypedPaths）を削除
Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths' -Recurse -Force -ErrorAction SilentlyContinue
# ※ エクスプローラー（タスクバー/デスクトップ）は Windows が数秒で自動復帰する（戻らなければサインアウト/再起動）
```

##### B-14. C:\ 直下の非標準フォルダの確認・削除

```powershell
# C:\ 直下の標準以外のフォルダを列挙（研修生が作成した可能性）
$std = @('Windows','Program Files','Program Files (x86)','ProgramData','Users','PerfLogs',
         'Recovery','$Recycle.Bin','System Volume Information','$WinREAgent','$SysReset',
         'OneDriveTemp','Intel','Drivers','AMD','NVIDIA','Config.Msi','Documents and Settings',
         'inetpub','Quarantine','SWSetup')
Get-ChildItem 'C:\' -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $std -notcontains $_.Name } | ForEach-Object { "C:\$($_.Name)" }
```

```powershell
# 上で出た不要フォルダを削除（<名前> を実際の名前に置き換える。管理者権限が必要な場合あり）
Remove-Item "C:\<名前>" -Recurse -Force
```

##### B-15. ごみ箱を空にする

```powershell
# ごみ箱を空にする
Clear-RecycleBin -Force
```

##### B-16. 点検（手動）

削除後、こちらで点検する（各項目に OK/NG が表示される）。

```powershell
# 確認（手動。スクリプトを使わず点検する）
$dl = (Get-ChildItem "$env:USERPROFILE\Downloads" -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' }).Count
if ($dl -eq 0) { Write-Host "OK: ダウンロードフォルダ 空" } else { Write-Host "NG: ダウンロード $dl 件残存" }
$shots = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Screenshots'
$sc = (Get-ChildItem $shots -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' }).Count
if ($sc -eq 0) { Write-Host "OK: スクリーンショット なし" } else { Write-Host "NG: スクリーンショット $sc 件残存" }
if (Test-Path "$env:APPDATA\Zoom\data") { Write-Host "NG: Zoom ログイン情報 残存" } else { Write-Host "OK: Zoom ログインなし" }
foreach ($p in @("$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache", "$env:APPDATA\Microsoft\Teams",
                 "$env:LOCALAPPDATA\Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe\LocalCache",
                 "$env:LOCALAPPDATA\Microsoft\Outlook", "$env:APPDATA\Microsoft\Outlook")) {
  if (Test-Path $p) { Write-Host "NG: Teams/Outlook ログイン情報 残存 ($p)" } else { Write-Host "OK: ログイン情報なし ($p)" }
}
$prof = Get-ChildItem 'HKCU:\Software\Microsoft\Office' -ErrorAction SilentlyContinue |
  Where-Object { $_.PSChildName -match '^\d+\.\d+$' } |
  ForEach-Object { "HKCU:\Software\Microsoft\Office\$($_.PSChildName)\Outlook\Profiles",
                   "HKCU:\Software\Microsoft\Office\$($_.PSChildName)\Common\Identity" } |
  Where-Object { Test-Path $_ }
if (-not $prof) { Write-Host "OK: Outlook プロファイル・Office サインインなし" } else { $prof | ForEach-Object { Write-Host "NG: 残存 ($_)" } }
$cred = cmdkey /list | Select-String -Pattern '(?:LegacyGeneric|Domain|WindowsLive|MicrosoftAccount):\S+' -AllMatches |
  ForEach-Object { $_.Matches.Value } | Where-Object { $_ -match 'MicrosoftOffice|Teams|Outlook' }
if (-not $cred) { Write-Host "OK: Windows 資格情報（Teams/Outlook/Office）なし" } else { $cred | ForEach-Object { Write-Host "NG: 資格情報 残存 ($_)" } }
$tk = (Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts" -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
if ($tk -eq 0) { Write-Host "OK: 職場または学校アカウント なし" } else { Write-Host "NG: 職場または学校アカウント $tk 件残存" }
foreach ($p in @("$env:LOCALAPPDATA\Microsoft\OneAuth", "$env:LOCALAPPDATA\Microsoft\TokenBroker\Cache")) {
  $n = (Get-ChildItem $p -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
  if ($n -eq 0) { Write-Host "OK: サインインキャッシュ なし ($p)" } else { Write-Host "NG: サインインキャッシュ $n 件残存 ($p)" }
}
foreach ($p in @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History")) {
  if (Test-Path $p) { Write-Host "NG: ブラウザ履歴 残存 ($p)" } else { Write-Host "OK: ブラウザ履歴なし ($p)" }
}
$rc = (Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent" -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
if ($rc -eq 0) { Write-Host "OK: エクスプローラー最近使ったファイル なし" } else { Write-Host "NG: エクスプローラー履歴 $rc 件残存" }
$std = @('Windows','Program Files','Program Files (x86)','ProgramData','Users','PerfLogs',
         'Recovery','$Recycle.Bin','System Volume Information','$WinREAgent','$SysReset',
         'OneDriveTemp','Intel','Drivers','AMD','NVIDIA','Config.Msi','Documents and Settings',
         'inetpub','Quarantine','SWSetup')
$extra = Get-ChildItem 'C:\' -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $std -notcontains $_.Name }
if (-not $extra) { Write-Host "OK: C:\ 直下 非標準フォルダなし" } else { $extra | ForEach-Object { Write-Host "NG: C:\ 直下 非標準フォルダ残存 (C:\$($_.Name))" } }
```
