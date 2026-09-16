# 研修環境セットアップ手順（上流工程研修）

> **対象:** 上流工程研修用の PC を用意する運営担当者。下流工程研修・AI駆動開発研修の環境は [00_DevEnvironmentSetup.md](00_DevEnvironmentSetup.md) を参照。

上流工程研修では、**Claude デスクトップアプリ**（Windows 版）の **Code タブ**から Claude Code の機能を使う。作業はすべて Windows 上で行うため、WSL（Ubuntu）と VSCode のセットアップは不要である。

この手順書が扱うのは、**PC にツールを入れて動作確認するところまで**である。受講者が行うアカウント連携・配布フォルダの配置・研修当日の起動は [05_UpstreamAccountSetup.md](05_UpstreamAccountSetup.md)、研修終了後のクリーンアップは [06_UpstreamCleanup.md](06_UpstreamCleanup.md) で扱う。

## インストールするもの

| ツール | 用途 | この手順書での確認方法 |
|---|---|---|
| Git for Windows（Git Bash） | Claude デスクトップアプリの Code タブが動くための必須条件。研修中に Git の操作は行わない | `git --version` |
| Python 3.12 系 | 要件定義書（Word）・画面設計書（Excel）・レビュー会スライドの生成 | `python --version` が `Python 3.12.x` であること |
| Python ライブラリ 3種<br>（python-docx・openpyxl・python-pptx） | 同上。Word・Excel・スライドを作るために使う | `python -c "import docx, openpyxl, pptx"` |
| Node.js 22 系以降 | Claude Code が補助ツールを動かすときに使う。受講者が直接打つことはない | `node -v` が `v22.x.x` 以降であること（新しく入れる場合は 22 系。npm は Node.js に同梱されるので別途の導入は不要） |
| LibreOffice（最新の安定版） | 生成した Word・Excel・スライドを開いて確認する | `soffice.exe` があること |
| Claude デスクトップアプリ | 全演習の主軸。Claude Code 本体はアプリに含まれるため、CLI の別途導入は不要 | `claude.exe` があること |

---

## セットアップ

### 1. ツールのインストール

Windows のスタートメニューで **「PowerShell」** を検索し、結果の中の **「Windows PowerShell」** を**管理者として起動**する（右クリック → **管理者として実行**）。

> **注意:** 検索結果には「Windows PowerShell ISE」も並ぶが、**ISE は選ばない**（この手順書のスクリプトは ISE では入力待ちで止まることがある）。PowerShell 7 を新しく入れる必要はない。研修は Windows に最初から入っている 5 系のままで進められる。

まず、この後で使うインストール用のコマンド（`winget`）が使えるかを確認する。

```powershell
# 確認
winget --version
```

> **結果例**
> ```
> v1.x.x
> ```
>
> `'winget' は、内部コマンドまたは外部コマンド...として認識されていません` と表示された場合は、この後の **A は使えない**ので **B の手順**を実施する。

以下の **A**（スクリプトで一括）または **B**（手動で1つずつ）のどちらかを実施する。**A を推奨**する。

> **インストールの順番:** Git for Windows を入れてから Claude デスクトップアプリを入れる。逆の順番で入れた場合は、Git のインストール後に Claude デスクトップアプリを終了して起動し直す（起動中のアプリは Git を認識しないため）。A のスクリプトはこの順番で実行する。

#### ✅ A. スクリプトで一括インストール（推奨）

##### A-1. setup-upstream.ps1 で一括インストール

```powershell
# ダウンロード（TEMP に保存。作業フォルダの権限に依存しない）
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/setup-upstream.ps1 -OutFile "$env:TEMP\setup-upstream.ps1"
```

> **補足:** `アクセスが拒否されました` と出る場合は、保存先フォルダの書き込み権限が原因である。`$env:TEMP` に保存すれば回避できる。
>
> **ダウンロード自体が失敗する場合**（応答が返らない、証明書や接続のエラーが出る）は、社内ネットワークの制限が原因である。ネットワーク管理者に確認すること。

```powershell
# 実行（確認を聞かれるので y を入力して Enter を押す）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\setup-upstream.ps1"
```

> `インストールを実行しますか？ [y/N]` と表示されたら、`y` を入力して `Enter` を押す。`Enter` だけを押すと `中止しました` となって何も行われないので、その場合は上のコマンドをもう一度実行する。
>
> `このシステムではスクリプトの実行が無効になっているため...` と表示されて実行できない場合は、会社の設定でスクリプトの実行が禁止されている。**B の手順**を実施する。

Git for Windows・Python 3.12・Python ライブラリ3種・Node.js 22・LibreOffice・Claude デスクトップアプリの順にインストールされる。インストール済みのものは自動でスキップされる。途中で失敗した場合は、もう一度同じコマンドを実行すると成功済みのものはスキップされる。

> **Node.js だけは winget を使わない。** winget が返すバージョンの一覧は新しい順に約38件で打ち切られ、`OpenJS.NodeJS.LTS` は 24 系しか持たないため、22 系を指定する手段がない（実機で確認）。スクリプトは公式サイト（`https://nodejs.org/dist/latest-v22.x/`）から MSI を取得して無人インストールする。B-4 と同じものを自動で行っているだけである。

> **22 系より新しい Node.js が既に入っている PC では、それを消して入れ直すことはしない。** 24 系などが入っていればそのまま使い、スクリプトは Node.js のインストールをスキップする。研修では受講者が `node` を直接打たないため、バージョンを揃える必要がない。確認の画面には黄色で `[OK] Node.js: v24.x.x ← 22 系ではありません（このまま研修に使えます）` と表示され、確認の最後にもう一度同じ内容が出る。どの PC が 22 系以外なのかは、この表示で分かる。

> **研修に要らないものは入れない。** このスクリプトは、winget が入れようとする依存パッケージを飛ばす指定（`--skip-dependencies`）を LibreOffice に付けている。winget の LibreOffice のパッケージ定義は **Microsoft Visual C++ 再頒布可能パッケージ**（`Microsoft.VCRedist.2015+.x64`）を依存として宣言しているため、これを付けないとそちらまで入る（社内PCではアプリの導入に申請が必要なため、巻き込まないようにしている）。
>
> LibreOffice が起動しない場合に限り、このランタイムが要る。判断は「画面付きアプリの起動確認」で行う。
>
> **このルートでは、キャンセルが必要な画面は出ない想定である。** 見覚えのないインストール画面が出た場合は、進める前に APD GrowthTech推進部（この手順書の管理者）へ確認すること。

インストールが終わると、**続けて確認（A-2 と同じ内容）が自動で実行される**。

> **結果例**（末尾の部分）
> ```
> === インストール確認 ===
>
> [OK] Git for Windows: git version 2.x.x.windows.1
> [OK] Python: Python 3.12.x
> ...
> === 確認完了: すべて [OK] です ===
> ```

##### A-2. setup-upstream.ps1 -Check でインストール確認

A-1 の最後に出た確認をもう一度実行したいときは、以下を実行する。

```powershell
# 確認（-Check は確認のみ。インストールは行わない。何度実行しても安全）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\setup-upstream.ps1" -Check
```

> 各項目に `[OK]` が表示されていればインストール完了。この確認はスクリプトが PATH（コマンドの探し先の一覧）を読み直してから判定するため、**PowerShell を開き直さずにそのまま実行してよい**。
>
> `[NG]` の場合は、該当するツールの**インストール手順**（B-1〜B-6）を実施し、もう一度この確認を実行する。B の手順の中で PowerShell を開き直した場合も、戻ってきたらこの確認をそのまま実行してよい。
>
> `npm` は Node.js に同梱されるため、別項目として表示されるが個別の導入手順は無い。Node.js が `[OK]` なら通常は `npm` も `[OK]` になる。

##### A-3. 後片付け

**「2. 動作確認（Git Bash）」まで終えてから**、ダウンロードしたスクリプトを削除する（動作確認で問題が出たときに、この確認をもう一度使うため）。

```powershell
# 後片付け
Remove-Item "$env:TEMP\setup-upstream.ps1" -ErrorAction SilentlyContinue
```

> 削除したあとで確認し直したくなった場合は、A-1 のダウンロードのコマンドから実行すれば元に戻せる。

**A-2 まで終えたら**「2. 動作確認（Git Bash）」へ進む（A-3 は動作確認のあとで行う）。

#### 🔧 B. 手動で1つずつインストール

各公式サイトからインストーラーをダウンロードして実行する。**B-1 から B-7 まで、この順番で実施する。**

> **重要（B ルート全体の前提）:** インストーラーが書き込んだ PATH は、**すでに開いている PowerShell には反映されない**。そのため、インストーラーを実行するステップ（**B-1・B-2・B-4**）では、**確認コマンドを実行する前に PowerShell をいったん閉じて、管理者として開き直す**こと。開き直さずに確認すると、正しくインストールできていても `'git' は、内部コマンドまたは外部コマンド...として認識されていません` と表示される。

##### B-1. Git for Windows のインストール

Claude デスクトップアプリの Code タブは、内部で Git Bash を使う。研修で Git の操作はしないが、これが入っていないと Code タブが動かない（Git Bash については「2. 動作確認（Git Bash）」で説明する）。

1. https://git-scm.com/download/win を開き、**64-bit Git for Windows Setup** をダウンロードする
2. インストーラーを実行する。選択肢は既定のまま進める。途中の **Adjusting your PATH environment** という画面で、**Git from the command line and also from 3rd-party software** が選ばれていることだけ確認する（既定でこれが選ばれている）

PowerShell を閉じて、管理者として開き直してから確認する。

```powershell
# 確認
git --version
```

> **結果例**
> ```
> git version 2.x.x.windows.1
> ```

##### B-2. Python 3.12 のインストール

> **注意:** 研修では **3.12 系**を使用する。他のバージョンだとライブラリが動かない場合がある。

1. https://www.python.org/downloads/windows/ を開く
2. **Python 3.12.x** の **Windows installer (64-bit)** をダウンロードする（一覧の上のほうにある最新版は 3.13 以降のことがあるため、**3.12** で始まるものを選ぶ）
3. インストーラーを実行し、最初の画面で **「Add python.exe to PATH」** にチェックを入れてから **Install Now** を押す

PowerShell を閉じて、管理者として開き直してから確認する。

```powershell
# 確認
python --version
```

> **結果例**
> ```
> Python 3.12.x
> ```
>
> **`3.12` 以外のバージョンが表示された場合:** すでに別のバージョンの Python が入っており、そちらが先に見つかっている。3.12 を追加で入れても表示は変わらない。PATH の並び順で 3.12 を先にするか、その PC では既存の Python を削除してから入れ直すこと。
>
> **何も表示されない場合:** Windows の「アプリ実行エイリアス」が Microsoft Store 版の python を指している。**設定 → アプリ → アプリ実行エイリアス** で `python.exe`・`python3.exe` をオフにしてから、PowerShell を開き直して再確認する。

##### B-3. Python ライブラリ3種のインストール

Word・Excel・スライドを作るためのライブラリを入れる。**管理者として開いた PowerShell** で実行する（B-2 の確認をした直後なら、その画面のままでよい）。

```powershell
# インストール
python -m pip install python-docx openpyxl python-pptx
```

```powershell
# 確認（何も表示されずに入力待ちに戻れば成功）
python -c "import docx, openpyxl, pptx"
```

> **注意:** パッケージ名（`python-docx`）と、読み込むときの名前（`docx`）が違う。確認のコマンドは上記のとおり入力する。
>
> **`ModuleNotFoundError` と表示された場合:** インストールが終わっていない。上のインストールのコマンドをもう一度実行する。
>
> **`SSLError` や `certificate verify failed` が出る場合:** 社内ネットワークの制限が原因である。ネットワーク管理者に確認すること。

##### B-4. Node.js 22 のインストール

> **既に Node.js が入っている場合は、先に `node -v` を実行する。** `v22` 以降（`v24` など）が表示されたら、この B-4 は飛ばしてよい。消して入れ直す必要はない。

> **注意:** 新しく入れる場合は **22 系**を使用する。公式サイトのトップに出る最新版は 22 系ではないことがあるため、以下のページから選ぶ。

1. https://nodejs.org/dist/latest-v22.x/ を開く
2. 一覧から **`node-v22.x.x-x64.msi`** をダウンロードする（研修用 PC は `x64` である。自分の PC の種類は **設定 → システム → バージョン情報 → システムの種類** で確認できる）
3. インストーラーを実行する。選択肢は既定のまま進める

> **注意:** 途中に **Tools for Native Modules**（`Automatically install the necessary tools...`）というチェックボックスの画面がある。**既定でオフなので、そのまま次へ進む**こと。ここにチェックを入れると、Chocolatey・Python・Visual Studio Build Tools を追加で入れにいき、数 GB かかる。研修では使わない。

PowerShell を閉じて、管理者として開き直してから確認する。

```powershell
# 確認（npm は Node.js に同梱されるため、別途の導入は不要）
node -v
npm -v
```

> **結果例**
> ```
> v22.x.x
> 10.x.x
> ```
>
> **`v22` 以外が表示された場合:** `v24` のように 22 より新しいバージョンであれば、そのままでよい（研修に使える）。`v20` のように 22 より古い場合は、**設定 → アプリ → インストールされているアプリ**で Node.js をアンインストールしてから、この B-4 をやり直す。Node.js は複数のバージョンを同時に入れられないため、入れ直しになる。

##### B-5. LibreOffice のインストール

Claude が作った Word・Excel・スライドを開いて確認するために使う。

1. https://www.libreoffice.org/download/download-libreoffice/ を開き、Windows 版をダウンロードする
2. インストーラーを実行する。選択肢は既定のまま進める

> 公式サイトのインストーラーは、winget のような依存パッケージの追加インストールを行わない。**Microsoft Visual C++ 再頒布可能パッケージ**を別途求められることは通常ない。

> 起動できることはこのあとの「2. 動作確認（Git Bash）」で確認する。配布フォルダのサンプルを開く確認は、受講者が [05_UpstreamAccountSetup.md](05_UpstreamAccountSetup.md) の「5. LibreOffice でファイルを開く」で行う。

##### B-6. Claude デスクトップアプリのインストール

1. ブラウザで https://claude.ai/download を開き、**Windows（x64）** 版のインストーラーをダウンロードして実行する
2. インストールが終わったら、いったんアプリを閉じる（サインインは受講者が [05_UpstreamAccountSetup.md](05_UpstreamAccountSetup.md) の「2. Claude デスクトップアプリへのサインイン」で行う）

> 起動できることはこのあとの「2. 動作確認（Git Bash）」で確認する。Code タブから配布フォルダを開く確認は、受講者が [05_UpstreamAccountSetup.md](05_UpstreamAccountSetup.md) の「4. Code タブで配布フォルダを開く」で行う。

##### B-7. 点検（手動）

B-1 から B-6 まで終えたら、こちらで一括点検する（各項目に OK/NG が表示される）。PowerShell をいったん閉じて、**管理者として開き直してから**実行する（PATH の変更が反映されていないと NG になる）。

```powershell
# 確認（手動。スクリプトを使わず点検する）
if (Get-Command git -CommandType Application -ErrorAction SilentlyContinue) { "OK: $(git --version)" } else { "NG: Git for Windows なし" }
if ((Get-Command python -CommandType Application -ErrorAction SilentlyContinue) -and ((python --version 2>&1) -like 'Python 3.12.*')) { "OK: $(python --version)" } else { "NG: Python 3.12 系なし" }
if (Get-Command python -CommandType Application -ErrorAction SilentlyContinue) { python -c "import docx, openpyxl, pptx" 2>$null; if ($LASTEXITCODE -eq 0) { "OK: Python ライブラリ3種" } else { "NG: Python ライブラリ不足" } } else { "NG: Python なし" }
$nodeVer = if (Get-Command node -CommandType Application -ErrorAction SilentlyContinue) { "$(node -v)" } else { '' }
if (-not $nodeVer) { "NG: Node.js なし" } elseif ($nodeVer -match '^v(\d+)\.' -and [int]$Matches[1] -ge 22) { if ($nodeVer -like 'v22.*') { "OK: Node.js $nodeVer" } else { "OK: Node.js $nodeVer（22 系ではありませんが、このまま研修に使えます）" } } else { "NG: Node.js 22 系以降なし（$nodeVer）" }
if (Get-Command npm -ErrorAction SilentlyContinue) { "OK: npm $(npm -v)" } else { "NG: npm なし（Node.js に同梱されます）" }
if ((Test-Path -LiteralPath "$env:ProgramFiles\LibreOffice\program\soffice.exe") -or (Test-Path -LiteralPath "${env:ProgramFiles(x86)}\LibreOffice\program\soffice.exe")) { "OK: LibreOffice" } else { "NG: LibreOffice なし" }
# Claude デスクトップアプリ（既定の場所とレジストリ〔Windows の設定の保管場所〕の両方から実行ファイルを探し、実在を確認する）
$claudePaths = @("$env:LOCALAPPDATA\AnthropicClaude\claude.exe", "$env:LOCALAPPDATA\Programs\Claude\Claude.exe", "$env:ProgramFiles\Claude\Claude.exe")
$claudeReg = Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } | Where-Object { $_.DisplayName -like 'Claude*' }
$claudeExe = $claudePaths + ($claudeReg | ForEach-Object { ($_.DisplayIcon -replace ',.*$', '').Trim('"'); if ($_.InstallLocation) { Join-Path $_.InstallLocation 'claude.exe' } }) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if ($claudeExe) { "OK: Claude デスクトップアプリ $claudeExe" } else { "NG: Claude デスクトップアプリなし" }
```

> すべて `OK` であれば完了。`NG` が出た場合は、まず PowerShell を閉じて開き直し、もう一度この点検を実行する（PATH が反映されていないだけのことがある）。それでも `NG` の項目は、対応する B の手順をやり直す。

B が完了したら「2. 動作確認（Git Bash）」へ進む。

---

### 2. 動作確認（Git Bash）

**Git Bash** は、Git for Windows に付属するコマンド画面である。スタートメニューから **「Git Bash」** を起動する。黒い画面が開いたら、以下を1行ずつ入力して `Enter` を押す。

> **なぜ Git Bash で確認するのか:** Claude デスクトップアプリの Code タブは、この Git Bash を通してコマンドを実行する。PowerShell で動いても Git Bash で動かなければ、研修中に同じエラーが出る。
>
> **注意:** すでに開いている Git Bash があれば、**閉じて開き直してから**実行する（インストールより前から開いていた画面には、入れた内容が反映されていない）。

```bash
git --version
```

```bash
python --version
```

```bash
node -v
```

```bash
npm -v
```

```bash
python -c "import docx, openpyxl, pptx"
```

```bash
curl -s -o /dev/null -w "Claude.ai: %{http_code}\n" https://claude.ai
```

> **結果の見かた**
> - 最初の4つは、それぞれバージョン（`git version 2.x.x`・`Python 3.12.x`・`v22.x.x` 以降・`10.x.x`）が表示されれば正常
> - 5つめは、**何も表示されずに入力待ちの行（`$` で始まる行）が戻れば正常**
> - 6つめは `Claude.ai: 200` と表示されれば正常（`301` などの 3 桁の数字で始まる応答でもつながっている）
>
> **うまくいかないときの行き先**
> - `command not found` と表示された → そのツールの手順（B-1・B-2・B-4）を見直す
> - PowerShell の確認（A-2 または B-7）で表示されたものと違うバージョンが表示された → PowerShell では正しくても Git Bash では別のものが見つかっている。PATH の並び順を確認すること
> - `Python 3.12` 以外のバージョンが表示された → B-2 を見直す
> - `v22` より古い Node.js が表示された → B-4 を見直す（`v24` など 22 より新しいものはそのままでよい）
> - `ModuleNotFoundError` と表示された → **PowerShell を開いて** B-3 を実施する（B-3 は PowerShell で行う手順である）
> - `Claude.ai: 000`・`407`・`403` と表示された、またはエラーになった → 社内ネットワークの設定が原因である。ネットワーク管理者に確認すること

#### 画面付きアプリの起動確認

コマンドで確認できない2つは、実際に起動して確かめる。

1. スタートメニューから **「LibreOffice」** を起動し、スタートセンターの画面が出たら閉じる
   - 起動せず、`VCRUNTIME140.dll が見つかりません` のようなエラーが出る場合は、**Microsoft Visual C++ 再頒布可能パッケージ**（`Microsoft.VCRedist.2015+.x64`）が必要である。社内の申請を経てから `winget install --exact --id Microsoft.VCRedist.2015+.x64` で導入する
2. スタートメニューから **「Claude」** を起動し、**サインイン画面が表示される**ことを確認したら閉じる（サインインは受講者が行うため、ここではしない）

> Claude デスクトップアプリが起動しない場合は B-6 を、LibreOffice が起動しない場合は B-5 をやり直す。

#### 後片付け

A ルートで進めた場合は、ここで **A-3** を実施して `setup-upstream.ps1` を削除する。

---

## 付録: 検証用のアンインストール

手順書どおりに入るかを 1 台で試すとき、**入れたものを全部消して最初からやり直す**ためのスクリプトである。研修生の PC には使わない（研修終了後のクリーンアップは 06 を参照。あちらはツール本体を残す）。

```powershell
# ダウンロード
Invoke-WebRequest -Uri https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/uninstall-upstream.ps1 -OutFile "$env:TEMP\uninstall-upstream.ps1"
```

```powershell
# 実行（確認を聞かれるので y を入力して Enter を押す。確認のみは末尾に -Check を付ける）
powershell -ExecutionPolicy Bypass -File "$env:TEMP\uninstall-upstream.ps1"
```

Claude デスクトップアプリ → LibreOffice → Node.js → Python 3.12 → Git for Windows の順（インストールと逆順）に削除し、続けて設定とキャッシュ（`%APPDATA%\Claude`・`%USERPROFILE%\.claude` 系・`%APPDATA%\LibreOffice`・`%APPDATA%\Python`・pip と npm のキャッシュ・`.bash_history`・`.gitconfig`）を消す。Python ライブラリ3種は Python 本体と一緒に消える。

削除は winget で行い、winget で消せないものは「プログラムと機能」の登録（MSI の製品コード、または無人アンインストールのコマンド）から削除する。どちらもできないものは名前を表示するので、**設定 → アプリ**から手動で削除する。

> **LibreOffice の削除には数分かかる。** その間、画面には何も出ない。止まったように見えても待つこと。

> **重要:** 実行後は PowerShell を閉じて開き直す。PATH の変更が反映されないまま `setup-upstream.ps1` を実行すると、消したはずのツールが見つかったように見える。

---

## この後の手順

PC の準備はここまでである。**A-2 または B-7 の点検がすべて `[OK]` になり、上の起動確認も通ってから受講者に渡すこと。** 続きは以下で行う。

| 文書 | 誰が | 内容 |
|---|---|---|
| [05_UpstreamAccountSetup.md](05_UpstreamAccountSetup.md) | 受講者 | アカウント作成、Claude デスクトップアプリへのサインイン、配布フォルダの配置、Code タブでの読み込み、研修当日の起動 |
| [06_UpstreamCleanup.md](06_UpstreamCleanup.md) | 運営 | 研修終了後、PC をこの手順書の完了時点の状態に戻す |
