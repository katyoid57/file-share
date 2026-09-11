# 研修環境セットアップ（Windows側・上流工程研修）
# 実行: powershell -ExecutionPolicy Bypass -File .\setup-upstream.ps1          … インストールを行い、完了後に確認（-Check 相当）も自動実行する
# 確認: powershell -ExecutionPolicy Bypass -File .\setup-upstream.ps1 -Check   … 確認のみ（read-only。何度でも安全に実行可）
#   Git for Windows → Python 3.12 → Python ライブラリ3種 → Node.js 22 → LibreOffice → Claude デスクトップアプリ
#   の順にインストールする。インストール済みのものは自動でスキップする。
#   ※ Git for Windows は Claude デスクトップアプリの Code タブが動くための必須条件のため、アプリより先に入れる。
#   ※ Windows PowerShell 5.1 で動作する範囲で書いている（研修では 7 系を導入しない）。
param([switch]$Check)

$ErrorActionPreference = 'Continue'

# 研修で使うバージョン。提案資料の「受講環境と事前セットアップ」に合わせている。
$PythonVersion = '3.12'                                   # Python は 3.12 系
$NodeMajor     = '22'                                     # Node.js は 22 系（LTS）
$PyLibs        = @('python-docx', 'openpyxl', 'python-pptx')  # Word・Excel・スライドの生成に使う
$PyImportTest  = 'import docx, openpyxl, pptx'            # ライブラリ名と読み込み名が違うため別に持つ

# 合否の判定条件。インストール時と確認時で基準がずれないよう1か所に置く。
$PythonPattern = "Python $PythonVersion.*"
$NodePattern   = "v$NodeMajor.*"

# LibreOffice の実行ファイル。64bit 版と 32bit 版で置き場所が違うため両方を候補にする。
$SofficeCandidates = @( (Join-Path $env:ProgramFiles 'LibreOffice\program\soffice.exe') )
# 32bit 版の置き場所。環境変数が無い場合に Join-Path が失敗するため、あるときだけ足す。
if (${env:ProgramFiles(x86)}) {
  $SofficeCandidates += (Join-Path ${env:ProgramFiles(x86)} 'LibreOffice\program\soffice.exe')
}

$ContactNote = '解決しない場合は、手順書の「B. 手動で1つずつインストール」で該当のツールを入れ直してください。'

# winget が見つからずインストールを行わなかったときに立てる。最後の自動確認を抑えるために使う。
$script:SetupAborted = $false

# 別プロセスのインストーラーが書き込んだ PATH を、実行中のこのセッションに取り込む。
# （PATH の変更は起動中のウィンドウには反映されないため、インストール直後の確認のために読み直す）
function Update-SessionPath {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = ($machine, $user | Where-Object { $_ }) -join ';'
}

# コマンドが PATH から解決できるか調べ、実行ファイルのパスを返す（見つからなければ $null）。
# ※ WindowsApps 配下（Microsoft Store のアプリ実行エイリアス）を除外してはいけない。winget 自身が
#    そこにあるほか、手順書の B-7 と Git Bash での確認はエイリアスもそのまま見るため、除外すると
#    スクリプトだけが別の python を見て判定が食い違う。エイリアスの空振りは表示側で見分ける。
function Resolve-Tool {
  param([string]$Cmd)
  $c = Get-Command $Cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($c) { return $c.Source }
  return $null
}

# python --version の1行目を返す。コマンドが無ければ $null、実行できても何も返さなければ空文字。
# （Microsoft Store のアプリ実行エイリアスが python を指していると、空文字になる）
function Get-PythonVersionText {
  $py = Resolve-Tool 'python'
  if (-not $py) { return $null }
  return "$(& $py --version 2>&1 | Select-Object -First 1)"
}

# node -v の1行目を返す。コマンドが無ければ $null。
function Get-NodeVersionText {
  $node = Resolve-Tool 'node'
  if (-not $node) { return $null }
  return "$(& $node -v 2>&1 | Select-Object -First 1)"
}

# 条件が満たされるまで待つ（インストーラーが終了したあとも展開が続くアプリのため）。
function Wait-Until {
  param([scriptblock]$Condition, [int]$Seconds = 60)
  $deadline = (Get-Date).AddSeconds($Seconds)
  while ((Get-Date) -lt $deadline) {
    Update-SessionPath
    if ([bool](& $Condition)) { return $true }
    Start-Sleep -Seconds 3
  }
  return $false
}

# python コマンドの状態を返す。
#   missing … コマンドが無い
#   ok      … 研修で使うバージョン
#   other   … 別のバージョンが先に見つかる
#   alias   … Microsoft Store のアプリ実行エイリアス（--version がバージョンを返さない）
function Get-PythonState {
  $t = Get-PythonVersionText
  if ($null -eq $t) { return 'missing' }
  if ($t -like $PythonPattern) { return 'ok' }
  if ($t -match '^Python \d') { return 'other' }
  return 'alias'
}

function Test-PythonVersion {
  $t = Get-PythonVersionText
  return ($t -and ($t -like $PythonPattern))
}

function Test-NodeVersion {
  $t = Get-NodeVersionText
  return ($t -and ($t -like $NodePattern))
}

# Python ライブラリ3種を読み込めるかどうかを返す。
function Test-PyLibs {
  $py = Resolve-Tool 'python'
  if (-not $py) { return $false }
  & $py -c $PyImportTest 2>&1 | Out-Null
  return ($LASTEXITCODE -eq 0)
}

# LibreOffice の実行ファイルを探す（見つからなければ $null）。
function Get-SofficeExe {
  foreach ($c in $SofficeCandidates) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  return $null
}

# Claude デスクトップアプリの実行ファイルを探し、そのパスを返す（見つからなければ $null）。
# ※ インストール先を決め打ちできないため、既定の場所を見たあと、レジストリのアンインストール情報
#    （DisplayIcon・InstallLocation）から実行ファイルの場所を引く。どちらもファイルの存在まで確認する。
function Get-ClaudeDesktop {
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA 'AnthropicClaude\claude.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Claude\Claude.exe'),
    (Join-Path $env:ProgramFiles  'Claude\Claude.exe')
  )
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { return $c }
  }

  # レジストリのアンインストール情報（32bit 版の置き場所も見る）
  $uninstallKeys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )
  $entries = Get-ChildItem $uninstallKeys -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
    Where-Object { $_.DisplayName -like 'Claude*' }

  foreach ($e in $entries) {
    # DisplayIcon は "C:\...\claude.exe,0" のようにアイコンの番号や引用符が付くことがあるため落とす
    if ($e.DisplayIcon) {
      $exe = ($e.DisplayIcon -replace ',.*$', '').Trim('"')
      if ($exe -and (Test-Path -LiteralPath $exe)) { return $exe }
    }
    if ($e.InstallLocation) {
      $exe = Join-Path $e.InstallLocation 'claude.exe'
      if (Test-Path -LiteralPath $exe) { return $exe }
    }
  }
  return $null
}

# winget でインストールする。Ids は上から順に試し、成功した時点で終了する
# （パッケージIDは提供元の都合で変わることがあるため候補を複数持たせる）。
# Probe には「入ったかどうかを判定するスクリプトブロック」を渡す。winget は
# 「再起動が必要」「既にインストール済み」などでも 0 以外を返すため、終了コードだけで失敗と決めない。
# Step には手順書の該当ステップ（B-1 等）を渡す。失敗時の案内に出す。
function Install-WingetPackage {
  param([string]$Name, [string[]]$Ids, [string]$Version, [scriptblock]$Probe, [string]$Step, [switch]$SkipDependencies)

  foreach ($id in $Ids) {
    # 依存パッケージを入れない指定。社内PCではアプリの導入に申請が要るため、研修で要らないものを
    # 巻き込まない。LibreOffice は winget のパッケージ定義が Microsoft.VCRedist.2015+.x64 を
    # 依存として宣言しているので、これを付けないと VC++ ランタイムまで入る。
    $extra = @()
    if ($SkipDependencies) { $extra += '--skip-dependencies' }

    # ※ winget の画面出力を Out-Host に流す。そのままだと関数の戻り値に文字列が混ざり、
    #    呼び出し側の if 判定が常に成立してしまう。
    if ($Version) {
      Write-Host "  winget install $id --version $Version を実行します。"
      winget install --exact --id $id --version $Version --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity @extra | Out-Host
    } else {
      Write-Host "  winget install $id を実行します。"
      winget install --exact --id $id --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity @extra | Out-Host
    }
    $code = $LASTEXITCODE

    if ($code -eq 0) { return $true }

    if ($Probe) {
      Update-SessionPath
      if ([bool](& $Probe)) {
        Write-Host "  winget は終了コード $code を返しましたが、インストールは確認できました。"
        return $true
      }
    }
    Write-Host "  $id のインストールに失敗しました（終了コード $code）。" -ForegroundColor Yellow
  }
  Write-Host "[NG] $Name のインストールに失敗しました。手順書の $Step を実施してください。" -ForegroundColor Red
  Write-Host "     $ContactNote"
  return $false
}

# 公式サイトから Node.js の指定メジャーバージョンの MSI を取得して無人インストールする。
# winget のバージョン一覧は LTS の移動や件数の打ち切りで 22 系を拾えないことがあるため、
# こちらを確実な経路として用意する（手順書の B-4 と同じものを自動で行う）。
function Install-NodeFromOfficialSite {
  param([string]$Major)

  $indexUrl = "https://nodejs.org/dist/latest-v$Major.x/"
  Write-Host "  $indexUrl から $Major 系の最新版を探します。"
  try {
    $page = Invoke-WebRequest -Uri $indexUrl -UseBasicParsing -ErrorAction Stop
  } catch {
    Write-Host "  一覧を取得できませんでした: $($_.Exception.Message)" -ForegroundColor Yellow
    return $false
  }

  $m = [regex]::Match("$($page.Content)", "node-v$Major\.\d+\.\d+-x64\.msi")
  if (-not $m.Success) {
    Write-Host '  x64 の MSI が見つかりませんでした。' -ForegroundColor Yellow
    return $false
  }

  $file = $m.Value
  $msi  = Join-Path $env:TEMP $file
  Write-Host "  $file をダウンロードします。"
  try {
    Invoke-WebRequest -Uri ($indexUrl + $file) -OutFile $msi -UseBasicParsing -ErrorAction Stop
  } catch {
    Write-Host "  ダウンロードに失敗しました: $($_.Exception.Message)" -ForegroundColor Yellow
    return $false
  }

  # /qn は無人インストール。任意機能（Tools for Native Modules）は選ばれない。
  Write-Host '  インストールします（画面は出ません）。'
  # ※ PowerShell では二重引用符の中の引用符はバッククォートで escape する（\" は無効）。
  #    パスに空白が含まれても壊れないよう、引数は1本の文字列にして引用符で囲む。
  $msiArgs = "/i `"$msi`" /qn /norestart"
  $proc = Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -PassThru
  Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue

  # 3010 は「成功したが再起動が必要」
  if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
    Write-Host "  msiexec が終了コード $($proc.ExitCode) を返しました。" -ForegroundColor Yellow
  }
  Update-SessionPath
  return (Test-NodeVersion)
}

# ===== 確認モード（-Check）: インストール状況を確認する（read-only）=====
function Invoke-Check {
  Update-SessionPath

  Write-Host '=== インストール確認 ===' -ForegroundColor Cyan
  Write-Host ''

  $ng = 0

  # Git for Windows
  $git = Resolve-Tool 'git'
  if ($git) {
    Write-Host "[OK] Git for Windows: $(& $git --version 2>&1 | Select-Object -First 1)" -ForegroundColor Green
  } else {
    $ng++; Write-Host '[NG] Git for Windows: git コマンドが見つかりません（手順書の B-1）' -ForegroundColor Red
  }

  # Python（バージョンが 3.12 系かどうかまで見る）
  $pv = Get-PythonVersionText
  switch (Get-PythonState) {
    'ok' {
      Write-Host "[OK] Python: $pv" -ForegroundColor Green
    }
    'missing' {
      $ng++; Write-Host '[NG] Python: python コマンドが見つかりません（手順書の B-2）' -ForegroundColor Red
    }
    'other' {
      $ng++
      Write-Host "[NG] Python: $pv（研修では $PythonVersion 系を使用します）" -ForegroundColor Red
      Write-Host "     別のバージョンが先に見つかっています。$PythonVersion を入れ直しても表示は変わりません。$ContactNote"
    }
    default {
      # Microsoft Store のアプリ実行エイリアス。--version がバージョンではなく案内文を返す
      $ng++
      Write-Host '[NG] Python: python コマンドが Microsoft Store のアプリ実行エイリアスを指しています' -ForegroundColor Red
      Write-Host '     設定 → アプリ → アプリ実行エイリアス で python.exe・python3.exe をオフにしてください（手順書の B-2 の注記）。'
    }
  }

  # Python ライブラリ3種（読み込めるかどうかで確認する）
  if ((Get-PythonState) -eq 'missing') {
    # Python が無いと確認そのものができない。行を出さずに飛ばすと [NG] の件数が実態より少なくなる。
    $ng++; Write-Host '[NG] Python ライブラリ: Python が見つからないため確認できません（手順書の B-2 → B-3）' -ForegroundColor Red
  } elseif (Test-PyLibs) {
    Write-Host "[OK] Python ライブラリ: $($PyLibs -join ' / ') を読み込めました" -ForegroundColor Green
  } else {
    $ng++; Write-Host "[NG] Python ライブラリ: $($PyLibs -join ' / ') のいずれかが読み込めません（手順書の B-3）" -ForegroundColor Red
  }

  # Node.js（バージョンが 22 系かどうかまで見る）
  $nv = Get-NodeVersionText
  if ($null -eq $nv) {
    $ng++; Write-Host '[NG] Node.js: node コマンドが見つかりません（手順書の B-4）' -ForegroundColor Red
  } elseif ($nv -like $NodePattern) {
    Write-Host "[OK] Node.js: $nv" -ForegroundColor Green
  } else {
    $ng++
    Write-Host "[NG] Node.js: $nv（研修では $NodeMajor 系を使用します）" -ForegroundColor Red
    Write-Host "     別のバージョンが先に見つかっています。$ContactNote"
  }

  # npm（Node.js に同梱されるため個別の導入手順は無い。欠けていれば Node.js の入れ直しになる）
  $npm = Resolve-Tool 'npm'
  if ($npm) {
    Write-Host "[OK] npm: $(& $npm -v 2>&1 | Select-Object -First 1)" -ForegroundColor Green
  } else {
    $ng++; Write-Host '[NG] npm: npm コマンドが見つかりません（Node.js に同梱されます。手順書の B-4 をやり直してください）' -ForegroundColor Red
  }

  # LibreOffice（画面付きアプリのため、起動せず実行ファイルのバージョン情報を読む）
  $soffice = Get-SofficeExe
  if ($soffice) {
    Write-Host "[OK] LibreOffice: $((Get-Item -LiteralPath $soffice).VersionInfo.ProductVersion)" -ForegroundColor Green
  } else {
    $ng++; Write-Host '[NG] LibreOffice: soffice.exe が見つかりません（手順書の B-5）' -ForegroundColor Red
  }

  # Claude デスクトップアプリ
  $claude = Get-ClaudeDesktop
  if ($claude) {
    Write-Host "[OK] Claude デスクトップアプリ: $claude" -ForegroundColor Green
  } else {
    $ng++; Write-Host '[NG] Claude デスクトップアプリ: インストールが確認できません（手順書の B-6）' -ForegroundColor Red
  }

  Write-Host ''
  if ($ng -eq 0) {
    Write-Host '=== 確認完了: すべて [OK] です ===' -ForegroundColor Green
  } else {
    Write-Host "=== 確認完了: [NG] が $ng 件あります ===" -ForegroundColor Red
    Write-Host '[NG] の項目は、括弧内の手順（手順書の B-1〜B-6）を実施してから、もう一度この確認を実行してください。'
    Write-Host "$ContactNote"
  }
}

# ===== 実行モード: インストールする =====
function Invoke-Setup {
  if (-not (Resolve-Tool 'winget')) {
    Write-Host '[ERROR] winget（Windows パッケージマネージャー）が見つかりません。' -ForegroundColor Red
    Write-Host '手順書の「B. 手動で1つずつインストール」を実施してください。'
    $script:SetupAborted = $true
    return
  }

  # 1. Git for Windows（Claude デスクトップアプリより先に入れる）
  Write-Host ''
  Write-Host '=== Git for Windows のインストール ===' -ForegroundColor Cyan
  Update-SessionPath
  $git = Resolve-Tool 'git'
  if ($git) {
    Write-Host "→ 既にインストール済みのためスキップします。（$(& $git --version 2>&1 | Select-Object -First 1)）"
  } else {
    Install-WingetPackage -Name 'Git for Windows' -Ids @('Git.Git') -Probe { [bool](Resolve-Tool 'git') } -Step 'B-1' | Out-Null
  }

  # 2. Python 3.12
  Write-Host ''
  Write-Host "=== Python $PythonVersion のインストール ===" -ForegroundColor Cyan
  Update-SessionPath
  $pv = Get-PythonVersionText
  $pyState = Get-PythonState
  if ($pyState -eq 'ok') {
    Write-Host "→ 既にインストール済みのためスキップします。（$pv）"
  } else {
    if ($pyState -eq 'other') {
      Write-Host "→ $pv が入っていますが研修では $PythonVersion 系を使用するため、$PythonVersion を追加でインストールします。" -ForegroundColor Yellow
      Write-Host '   ※ 追加で入れても python コマンドが指す先は変わらない場合があります。その場合は確認で [NG] が残ります。' -ForegroundColor Yellow
    } elseif ($pyState -eq 'alias') {
      Write-Host "→ python コマンドが Microsoft Store のアプリ実行エイリアスを指しています。$PythonVersion をインストールします。" -ForegroundColor Yellow
    }
    Install-WingetPackage -Name "Python $PythonVersion" -Ids @("Python.Python.$PythonVersion") -Probe { Test-PythonVersion } -Step 'B-2' | Out-Null
  }

  # 3. Python ライブラリ3種
  Write-Host ''
  Write-Host '=== Python ライブラリのインストール ===' -ForegroundColor Cyan
  Update-SessionPath
  $py = Resolve-Tool 'python'
  if (-not $py) {
    Write-Host '[NG] Python ライブラリ: python コマンドが見つからないためインストールできません（手順書の B-2 → B-3）' -ForegroundColor Red
    Write-Host "     $ContactNote"
  } elseif (Test-PyLibs) {
    Write-Host "→ 既にインストール済みのためスキップします。（$($PyLibs -join ' / ')）"
  } else {
    Write-Host "  python -m pip install $($PyLibs -join ' ') を実行します。"
    & $py -m pip install $PyLibs | Out-Host
    # 終了コードだけで判断せず、実際に読み込めるかを見る
    if (-not (Test-PyLibs)) {
      Write-Host '[NG] Python ライブラリのインストールに失敗しました（手順書の B-3）' -ForegroundColor Red
      Write-Host '     証明書のエラー（certificate verify failed）が出ている場合は社内ネットワークの制限が原因です。ネットワーク管理者に確認してください。'
      Write-Host "     $ContactNote"
    }
  }

  # 4. Node.js 22（winget には 22 系が無いため、公式サイトの MSI を無人インストールする）
  Write-Host ''
  Write-Host "=== Node.js $NodeMajor のインストール ===" -ForegroundColor Cyan
  Update-SessionPath
  $nv = Get-NodeVersionText
  if ($nv -and ($nv -like $NodePattern)) {
    Write-Host "→ 既にインストール済みのためスキップします。（$nv）"
  } else {
    if ($nv) {
      Write-Host "→ $nv が入っていますが研修では $NodeMajor 系を使用するため、$NodeMajor を追加でインストールします。" -ForegroundColor Yellow
    }
    # winget は使わない。winget のバージョン一覧は新しい順に約38件で打ち切られ、
    # OpenJS.NodeJS.LTS は 24 系しか持たないため、22 系を指定する手段が無い（実機で確認）。
    if (-not (Install-NodeFromOfficialSite -Major $NodeMajor)) {
      Write-Host "[NG] Node.js $NodeMajor 系のインストールに失敗しました。手順書の B-4 を実施してください。" -ForegroundColor Red
      Write-Host "     $ContactNote"
    }
  }

  # 5. LibreOffice
  Write-Host ''
  Write-Host '=== LibreOffice のインストール ===' -ForegroundColor Cyan
  $soffice = Get-SofficeExe
  if ($soffice) {
    Write-Host "→ 既にインストール済みのためスキップします。（$((Get-Item -LiteralPath $soffice).VersionInfo.ProductVersion)）"
  } else {
    # -SkipDependencies: VC++ 再頒布可能パッケージを一緒に入れない（導入には申請が要るため）。
    # LibreOffice が起動しない場合だけ、手順書の指示に従って別途申請して入れる。
    Install-WingetPackage -Name 'LibreOffice' -Ids @('TheDocumentFoundation.LibreOffice') -Probe { [bool](Get-SofficeExe) } -Step 'B-5' -SkipDependencies | Out-Null
  }

  # 6. Claude デスクトップアプリ（Git for Windows のあとに入れる）
  Write-Host ''
  Write-Host '=== Claude デスクトップアプリのインストール ===' -ForegroundColor Cyan
  if (Get-ClaudeDesktop) {
    Write-Host '→ 既にインストール済みのためスキップします。'
  } else {
    $ok = Install-WingetPackage -Name 'Claude デスクトップアプリ' -Ids @('Anthropic.Claude', 'Anthropic.ClaudeDesktop') -Probe { [bool](Get-ClaudeDesktop) } -Step 'B-6'
    if ($ok) {
      # インストーラーが終了したあとも展開が続き、直後の確認では実行ファイルが見つからないことがある
      Write-Host '  展開が終わるのを待っています（最大90秒）。'
      if (-not (Wait-Until { [bool](Get-ClaudeDesktop) } 90)) {
        Write-Host '  実行ファイルをまだ確認できません。しばらく待ってから -Check で確認してください。' -ForegroundColor Yellow
      }
    } else {
      Write-Host '     B-6 では https://claude.ai/download から Windows（x64）版をダウンロードしてインストールします。'
    }
  }

  Write-Host ''
  Write-Host '=== インストール完了 ===' -ForegroundColor Green
  Write-Host 'このあとの「2. 動作確認（Git Bash）」は、Git Bash を新しく開いてから実施してください。' -ForegroundColor Yellow
}

# ===== エントリポイント =====
if ($Check) {
  Invoke-Check
} else {
  Write-Host 'これは「インストール実行」です。確認だけなら -Check を付けてください。' -ForegroundColor Yellow
  Write-Host '管理者として実行した PowerShell で行ってください（インストールに管理者権限が必要です）。'
  $ans = Read-Host 'インストールを実行しますか？ [y/N]'
  if ($ans -ne 'y' -and $ans -ne 'Y') {
    Write-Host '中止しました。もう一度実行するには同じコマンドを入力してください（確認のみは -Check を付けます）。'
    return
  }
  Invoke-Setup

  # インストールに続けて確認（-Check 相当）を自動実行する（read-only）
  # ※ winget が無くて何もインストールしていない場合は、[NG] の羅列を出しても混乱するだけなので出さない。
  if (-not $script:SetupAborted) {
    Write-Host ''
    Invoke-Check
  }
}
