# 研修PC アカウント残存チェック（Windows側・読み取り専用）
# 実行: powershell -ExecutionPolicy Bypass -File "$env:TEMP\diag.ps1"
# 検索: powershell -ExecutionPolicy Bypass -File "$env:TEMP\diag.ps1" -Account user@example.com
#   Teams の「ようこそ」画面などに前の利用者のアカウントが残る原因を特定するための調査用。
#   何も削除せず、ファイルも作らない（画面に表示するだけ）。何度実行しても安全。
#   -Account を付けると、そのメールアドレスがどのファイル・レジストリに書かれているかを検索する
#   （入力したアドレスはこの PC 内の検索にのみ使う。どこにも送信しない）。
#   原因が判明して cleanup.ps1 に反映したら、このスクリプトは削除する。

param([string]$Account)

$ErrorActionPreference = 'Continue'

# 残骸が見つかった項目番号を記録する（最後のまとめで番号だけ伝えられるようにするため）
$Hits = @()

function Write-Section($num, $title) {
  Write-Host ""
  Write-Host "=== $num. $title ===" -ForegroundColor Cyan
}
function Write-Found($msg) { Write-Host "  [残っている] $msg" -ForegroundColor Red }
function Write-None($msg)  { Write-Host "  [なし] $msg" -ForegroundColor Green }
function Write-Info($msg)  { Write-Host "  $msg" }

# ファイルの中身に指定文字列が含まれるかを調べる（テキスト／UTF-16／ASCII 混在に対応）。
function Test-FileContains($path, $needle) {
  try {
    $fi = Get-Item -LiteralPath $path -Force -ErrorAction Stop
    if ($fi.Length -gt 20MB) { return $false }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = [Text.Encoding]::Unicode.GetString($bytes) + [Text.Encoding]::UTF8.GetString($bytes)
    return ($text.IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -ge 0)
  } catch {
    return $false
  }
}

# バイナリからメールアドレス形式の文字列を拾う（表示用。取れない場合はファイル名を返す）
function Get-EmailsFromFile($path) {
  try {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = [Text.Encoding]::Unicode.GetString($bytes) + [Text.Encoding]::ASCII.GetString($bytes)
    return @([regex]::Matches($text, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}') |
             ForEach-Object { $_.Value } | Select-Object -Unique)
  } catch {
    return @()
  }
}

Write-Host "=== 研修PC アカウント残存チェック（読み取り専用・削除はしません）===" -ForegroundColor Cyan

# ---- 1. PC 自体の参加状態 ----
Write-Section 1 'PC のアカウント参加状態'
$ds = dsregcmd /status 2>$null
if ($ds) {
  $ds | Select-String 'AzureAdJoined|WorkplaceJoined|DomainJoined|Executing Account Name' |
    ForEach-Object { Write-Info $_.Line.Trim() }
  if ([bool]($ds | Select-String 'AzureAdJoined\s*:\s*YES') -or [bool]($ds | Select-String 'WorkplaceJoined\s*:\s*YES')) {
    Write-Found 'PC 自体が職場アカウントに参加しています（ファイル削除では消せません）'
    $Hits += 1
  } else {
    Write-None 'PC 自体は職場アカウントに参加していません'
  }
} else {
  Write-Info 'dsregcmd が実行できませんでした'
}

# ---- 2〜7: アカウント情報が残りうる既知の場所 ----
# 番号と場所の対応は最後のまとめで説明する。
$Targets = @(
  @{ No = 2; Name = 'WAM（AAD BrokerPlugin）';      Path = "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts" },
  @{ No = 3; Name = 'TokenBroker キャッシュ';       Path = "$env:LOCALAPPDATA\Microsoft\TokenBroker\Cache" },
  @{ No = 6; Name = 'OneAuth';                      Path = "$env:LOCALAPPDATA\Microsoft\OneAuth" },
  @{ No = 9; Name = 'IdentityCache';                Path = "$env:LOCALAPPDATA\Microsoft\IdentityCache" },
  @{ No = 10; Name = 'TokenBroker\Accounts';        Path = "$env:LOCALAPPDATA\Microsoft\TokenBroker\Accounts" },
  @{ No = 11; Name = 'Teams の LocalState';         Path = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalState" },
  @{ No = 12; Name = 'Teams の Settings（settings.dat）'; Path = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\Settings" },
  @{ No = 13; Name = 'Teams の LocalCache';         Path = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache" }
)
foreach ($t in $Targets) {
  Write-Section $t.No "$($t.Name)"
  Write-Info $t.Path
  $files = @(Get-ChildItem -Path $t.Path -Recurse -File -Force -ErrorAction SilentlyContinue)
  if ($files.Count -gt 0) {
    Write-Found "$($files.Count) 件"
    $mails = @()
    foreach ($f in ($files | Select-Object -First 30)) { $mails += Get-EmailsFromFile $f.FullName }
    $mails = @($mails | Select-Object -Unique)
    if ($mails.Count -gt 0) { $mails | ForEach-Object { Write-Info "- $_" } }
    $Hits += $t.No
  } else {
    Write-None 'ありません'
  }
}

# ---- 4. IdentityCRL ----
Write-Section 4 'IdentityCRL の保存済みアカウント'
$idcrl = @()
foreach ($k in @('StoredIdentities', 'UserExtendedProperties')) {
  Get-ChildItem "HKCU:\Software\Microsoft\IdentityCRL\$k" -ErrorAction SilentlyContinue |
    ForEach-Object { $idcrl += "$k : $($_.PSChildName)" }
}
if ($idcrl.Count -gt 0) {
  Write-Found "$($idcrl.Count) 件"
  $idcrl | ForEach-Object { Write-Info "- $_" }
  $Hits += 4
} else {
  Write-None 'IdentityCRL に保存済みアカウントはありません'
}

# ---- 5. IdentityStore キャッシュ ----
Write-Section 5 'IdentityStore キャッシュ（メールアドレス）'
$idstore = @()
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\IdentityStore\Cache' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
  $v = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
  if ($v.UserName -or $v.PrimaryEmailAddress) { $idstore += "$($v.UserName) / $($v.PrimaryEmailAddress)" }
}
if ($idstore.Count -gt 0) {
  Write-Found "$($idstore.Count) 件"
  $idstore | Select-Object -Unique | ForEach-Object { Write-Info "- $_" }
  $Hits += 5
} else {
  Write-None 'IdentityStore キャッシュにアカウントはありません'
}

# ---- 7. WorkplaceJoin 登録 ----
Write-Section 7 'WorkplaceJoin 登録（設定→メールとアカウント の登録元）'
$wpj = @(Get-ChildItem 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin' -Recurse -ErrorAction SilentlyContinue)
if ($wpj.Count -gt 0) {
  Write-Found "$($wpj.Count) 件"
  $wpj | ForEach-Object { Write-Info "- $($_.Name)" }
  $Hits += 7
} else {
  Write-None 'WorkplaceJoin の登録はありません'
}

# ---- 8. 関連プロセスの起動状況 ----
# 起動中のプロセスがあると、そのファイルはロックされて削除できない。
Write-Section 8 '関連プロセスの起動状況（起動中だと削除に失敗する）'
$procNames = @('ms-teams', 'msteams', 'Teams', 'msedgewebview2', 'olk', 'OUTLOOK', 'OneDrive',
               'Microsoft.SharePoint', 'msoia', 'WINWORD', 'EXCEL', 'POWERPNT', 'ONENOTE')
$running = @(Get-Process -Name $procNames -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
  Write-Found "起動中: $((($running | Select-Object -ExpandProperty ProcessName) | Select-Object -Unique) -join ', ')"
  $Hits += 8
} else {
  Write-None '関連プロセスは起動していません'
}

# ---- 14. メールアドレスの全文検索（-Account 指定時のみ）----
if ($Account) {
  Write-Section 14 "「$Account」がどこに書かれているかを検索"
  Write-Info '数分かかります。そのままお待ちください…'
  $searchRoots = @(
    "$env:LOCALAPPDATA\Microsoft",
    "$env:APPDATA\Microsoft",
    "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe",
    "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy",
    "$env:LOCALAPPDATA\Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe"
  )
  $fileHits = @()
  foreach ($root in $searchRoots) {
    if (-not (Test-Path $root)) { continue }
    Write-Info "検索中: $root"
    foreach ($f in @(Get-ChildItem -Path $root -Recurse -File -Force -ErrorAction SilentlyContinue)) {
      if (Test-FileContains $f.FullName $Account) { $fileHits += $f.FullName }
    }
  }
  Write-Info 'レジストリ（HKCU:\Software\Microsoft）を検索中…'
  $regHits = @()
  foreach ($k in @(Get-ChildItem 'HKCU:\Software\Microsoft' -Recurse -ErrorAction SilentlyContinue)) {
    try {
      $props = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
      foreach ($p in $props.PSObject.Properties) {
        if ("$($p.Name) $($p.Value)".IndexOf($Account, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
          $regHits += ($k.Name + ' → ' + $p.Name)
          break
        }
      }
    } catch { }
  }
  Write-Host ""
  if ($fileHits.Count -gt 0) {
    Write-Found "ファイル $($fileHits.Count) 件にアドレスが書かれています"
    $fileHits | ForEach-Object { Write-Info "- $_" }
  } else {
    Write-None 'ファイルにはアドレスは見つかりませんでした'
  }
  if ($regHits.Count -gt 0) {
    Write-Found "レジストリ $($regHits.Count) 件にアドレスが書かれています"
    $regHits | Select-Object -Unique | ForEach-Object { Write-Info "- $_" }
  } else {
    Write-None 'レジストリにはアドレスは見つかりませんでした'
  }
  if ($fileHits.Count -gt 0 -or $regHits.Count -gt 0) { $Hits += 14 }
}

# ---- まとめ ----
Write-Host ""
Write-Host "=== まとめ ===" -ForegroundColor Cyan
$Hits = @($Hits | Sort-Object -Unique)
if ($Hits.Count -eq 0) {
  Write-Host "  アカウントの残骸は見つかりませんでした。" -ForegroundColor Green
} else {
  Write-Host "  残っている項目: $($Hits -join ', ')" -ForegroundColor Red
  Write-Host "  → この番号を控えて連絡してください。"
  Write-Host ""
  Write-Host "  【番号ごとの意味】"
  if ($Hits -contains 1)  { Write-Host "   1: PC 自体が職場アカウントに参加。設定 → アカウント → メールとアカウント から切断が必要" }
  if ($Hits -contains 2)  { Write-Host "   2: WAM。cleanup.ps1 の削除対象" }
  if ($Hits -contains 3)  { Write-Host "   3: TokenBroker キャッシュ。cleanup.ps1 の削除対象" }
  if ($Hits -contains 4)  { Write-Host "   4: IdentityCRL。未対応" }
  if ($Hits -contains 5)  { Write-Host "   5: IdentityStore キャッシュ。未対応" }
  if ($Hits -contains 6)  { Write-Host "   6: OneAuth。cleanup.ps1 の削除対象（消えていなければ削除失敗か再作成）" }
  if ($Hits -contains 7)  { Write-Host "   7: WorkplaceJoin 登録。設定アプリから切断が必要" }
  if ($Hits -contains 8)  { Write-Host "   8: 関連プロセスが起動中。これが原因で削除に失敗している可能性が高い" }
  if ($Hits -contains 9)  { Write-Host "   9: IdentityCache。未対応" }
  if ($Hits -contains 10) { Write-Host "  10: TokenBroker\\Accounts。未対応" }
  if ($Hits -contains 11) { Write-Host "  11: Teams の LocalState。未対応（cleanup.ps1 は LocalCache のみ削除）" }
  if ($Hits -contains 12) { Write-Host "  12: Teams の Settings（settings.dat）。未対応" }
  if ($Hits -contains 13) { Write-Host "  13: Teams の LocalCache。Teams を起動すると作り直されるため、起動後なら正常" }
  if ($Hits -contains 14) { Write-Host "  14: 検索でアドレスの実際の置き場所が判明。上の一覧が対処すべき場所" }
}
Write-Host ""
Write-Host "  ※ このスクリプトは何も削除していません。"
