# 研修環境のアンインストール（Windows側・上流工程研修・検証用）
# 実行: powershell -ExecutionPolicy Bypass -File .\uninstall.ps1          … アンインストールし、完了後に確認（-Check 相当）も自動実行する
# 確認: powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Check   … 確認のみ（read-only。何度でも安全に実行可）
#   setup.ps1 で入れた6つ（Claude デスクトップアプリ・LibreOffice・Node.js・Python・Python ライブラリ・
#   Git for Windows）を削除し、設定とキャッシュも消して、何も入っていない状態に戻す。
#   セットアップを最初からやり直して検証するための道具であり、研修生の PC には使わない。
#   ※ 研修終了後の返却前クリーンアップは cleanup-upstream.ps1（ツール本体は残す）を使う。
#   ※ 管理者として実行すること。Windows PowerShell 5.1 で動作する範囲で書いている。
param([switch]$Check)

$ErrorActionPreference = 'Continue'

# アプリ本体を消したあとに残る設定・キャッシュ。消さないと「最初から」にならない。
$LeftoverPaths = @(
  "$env:APPDATA\Claude",
  "$env:LOCALAPPDATA\AnthropicClaude",
  "$env:LOCALAPPDATA\Claude",
  "$env:USERPROFILE\.claude",
  "$env:USERPROFILE\.claude.json",
  "$env:USERPROFILE\.claude.json.backup",
  "$env:APPDATA\LibreOffice",
  "$env:APPDATA\Python",
  "$env:LOCALAPPDATA\pip",
  "$env:LOCALAPPDATA\npm-cache",
  "$env:APPDATA\npm",
  "$env:APPDATA\npm-cache",
  "$env:USERPROFILE\.bash_history",
  "$env:USERPROFILE\.gitconfig"
)

function Update-SessionPath {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = ($machine, $user | Where-Object { $_ }) -join ';'
}

function Resolve-Tool {
  param([string]$Cmd)
  $c = Get-Command $Cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($c) { return $c.Source }
  return $null
}

function Get-SofficeExe {
  $cands = @( (Join-Path $env:ProgramFiles 'LibreOffice\program\soffice.exe') )
  if (${env:ProgramFiles(x86)}) { $cands += (Join-Path ${env:ProgramFiles(x86)} 'LibreOffice\program\soffice.exe') }
  foreach ($c in $cands) { if (Test-Path -LiteralPath $c) { return $c } }
  return $null
}

function Get-ClaudeDesktop {
  $cands = @(
    (Join-Path $env:LOCALAPPDATA 'AnthropicClaude\claude.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Claude\Claude.exe'),
    (Join-Path $env:ProgramFiles  'Claude\Claude.exe')
  )
  foreach ($c in $cands) { if (Test-Path -LiteralPath $c) { return $c } }
  return $null
}

function Get-PythonVersionText {
  $py = Resolve-Tool 'python'
  if (-not $py) { return $null }
  return "$(& $py --version 2>&1 | Select-Object -First 1)"
}

# 「プログラムと機能」の登録から、表示名が前方一致するものを返す。
function Get-ArpEntries {
  param([string]$NameLike)
  $keys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )
  return @(Get-ChildItem $keys -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
    Where-Object { $_.DisplayName -like "$NameLike*" })
}

# 削除対象。インストールと逆の順で消す。
$Apps = @(
  @{ Name = 'Claude デスクトップアプリ'; Ids = @('Anthropic.Claude', 'Anthropic.ClaudeDesktop');
     Arp = 'Claude';       Probe = { [bool](Get-ClaudeDesktop) } },
  @{ Name = 'LibreOffice';               Ids = @('TheDocumentFoundation.LibreOffice');
     Arp = 'LibreOffice';  Probe = { [bool](Get-SofficeExe) } },
  @{ Name = 'Node.js';                   Ids = @('OpenJS.NodeJS', 'OpenJS.NodeJS.LTS');
     Arp = 'Node.js';      Probe = { [bool](Resolve-Tool 'node') } },
  @{ Name = 'Python 3.12';               Ids = @('Python.Python.3.12');
     Arp = 'Python 3.12';  Probe = { (Get-PythonVersionText) -like 'Python 3.12*' } },
  @{ Name = 'Git for Windows';           Ids = @('Git.Git');
     Arp = 'Git';          Probe = { [bool](Resolve-Tool 'git') } }
)

# winget で削除する。失敗しても、この時点では成否を判定しない（呼び出し側が Probe で見る）。
function Uninstall-ByWinget {
  param([string[]]$Ids)
  foreach ($id in $Ids) {
    Write-Host "  winget uninstall $id を実行します。"
    winget uninstall --exact --id $id --silent --disable-interactivity --accept-source-agreements | Out-Host
    if ($LASTEXITCODE -eq 0) { return }
  }
}

# 「プログラムと機能」の登録から削除する。MSI は製品コードで、それ以外は無人アンインストールの
# コマンドが登録されていればそれを使う。どちらもできないものは、名前を出して手動に回す。
function Uninstall-ByArp {
  param([string]$NameLike)
  foreach ($e in (Get-ArpEntries -NameLike $NameLike)) {
    $code = [regex]::Match("$($e.UninstallString)", '\{[0-9A-Fa-f\-]{36}\}').Value
    if ("$($e.UninstallString)" -match 'msiexec' -and $code) {
      Write-Host "  msiexec /x $code を実行します（$($e.DisplayName)）。"
      Start-Process msiexec.exe -ArgumentList "/x $code /qn /norestart" -Wait | Out-Null
    } elseif ($e.QuietUninstallString) {
      Write-Host "  無人アンインストールを実行します（$($e.DisplayName)）。"
      Start-Process cmd.exe -ArgumentList '/c', "$($e.QuietUninstallString)" -Wait | Out-Null
    } else {
      Write-Host "  自動で削除できません。「設定 → アプリ」から手動で削除してください: $($e.DisplayName)" -ForegroundColor Yellow
    }
  }
}

# ===== 確認モード（-Check）: 残っていないかを確認する（read-only）=====
function Invoke-Check {
  Update-SessionPath

  Write-Host '=== アンインストール確認 ===' -ForegroundColor Cyan
  Write-Host ''

  $left = 0
  foreach ($app in $Apps) {
    if ([bool](& $app.Probe)) {
      $left++; Write-Host "[残] $($app.Name): まだ入っています" -ForegroundColor Red
    } else {
      Write-Host "[OK] $($app.Name): 削除済み" -ForegroundColor Green
    }
  }

  Write-Host ''
  $files = @($LeftoverPaths | Where-Object { Test-Path -LiteralPath $_ })
  if ($files.Count -eq 0) {
    Write-Host '[OK] 設定・キャッシュ: 残っていません' -ForegroundColor Green
  } else {
    $left++
    Write-Host '[残] 設定・キャッシュが残っています' -ForegroundColor Red
    $files | ForEach-Object { Write-Host "     $_" }
  }

  Write-Host ''
  if ($left -eq 0) {
    Write-Host '=== 確認完了: すべて削除済みです。setup.ps1 を最初から実行できます ===' -ForegroundColor Green
  } else {
    Write-Host "=== 確認完了: $left 件残っています ===" -ForegroundColor Red
    Write-Host 'アプリが起動しているとアンインストールできません。終了してから、もう一度実行してください。'
    Write-Host '自動で消せないものは「設定 → アプリ」から手動で削除してください。'
  }
}

# ===== 実行モード: アンインストールする =====
function Invoke-Uninstall {
  # 1. 起動していると削除できないアプリを終了する
  Write-Host ''
  Write-Host '=== 対象アプリの終了 ===' -ForegroundColor Cyan
  foreach ($proc in @('claude', 'soffice', 'soffice.bin', 'bash', 'mintty', 'node')) {
    if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
      Write-Host "  $proc を終了します。"
      Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
  }
  Start-Sleep -Seconds 2

  # 2. アプリの削除（インストールと逆の順）
  foreach ($app in $Apps) {
    Write-Host ''
    Write-Host "=== $($app.Name) の削除 ===" -ForegroundColor Cyan
    Update-SessionPath
    if (-not [bool](& $app.Probe)) {
      Write-Host '→ 入っていないためスキップします。'
      continue
    }

    Uninstall-ByWinget -Ids $app.Ids
    Update-SessionPath
    if ([bool](& $app.Probe)) {
      Write-Host '  winget では削除できませんでした。「プログラムと機能」の登録から削除します。'
      Uninstall-ByArp -NameLike $app.Arp
      Update-SessionPath
    }

    if ([bool](& $app.Probe)) {
      Write-Host "  まだ残っています。「設定 → アプリ」から手動で削除してください。" -ForegroundColor Yellow
    } else {
      Write-Host '  削除しました。'
    }
  }

  # 3. 設定・キャッシュの削除
  Write-Host ''
  Write-Host '=== 設定・キャッシュの削除 ===' -ForegroundColor Cyan
  $hit = $false
  foreach ($p in $LeftoverPaths) {
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $hit = $true
    Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $p) {
      Write-Host "  削除に失敗しました: $p" -ForegroundColor Red
    } else {
      Write-Host "  削除しました: $p"
    }
  }
  if (-not $hit) { Write-Host '  対象がありません。' }

  Write-Host ''
  Write-Host '=== アンインストール完了 ===' -ForegroundColor Green
  Write-Host 'PATH の変更を反映するため、PowerShell を閉じて開き直してください。' -ForegroundColor Yellow
}

# ===== エントリポイント =====
if ($Check) {
  Invoke-Check
} else {
  Write-Host 'これは「アンインストール実行」です（研修用に入れたツールを削除します）。確認だけなら -Check を付けてください。' -ForegroundColor Yellow
  Write-Host '対象: Claude デスクトップアプリ・LibreOffice・Node.js・Python 3.12・Python ライブラリ・Git for Windows と、その設定・キャッシュ。'
  Write-Host 'セットアップを最初からやり直して検証するための道具です。研修生の PC には使わないでください。'
  $ans = Read-Host 'アンインストールを実行しますか？ [y/N]'
  if ($ans -ne 'y' -and $ans -ne 'Y') {
    Write-Host '中止しました。確認のみは -Check を付けて実行できます。'
    return
  }
  Invoke-Uninstall

  Write-Host ''
  Invoke-Check
}
