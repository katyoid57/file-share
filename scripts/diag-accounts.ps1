# 研修PC アカウント残存チェック（Windows側・読み取り専用）
# 実行: powershell -ExecutionPolicy Bypass -File "$env:TEMP\diag-accounts.ps1"
#   Teams の「ようこそ」画面などに前の利用者のアカウントが残る原因を特定するための調査用。
#   何も削除せず、ファイルも作らない（画面に表示するだけ）。何度実行しても安全。
#   原因が判明して cleanup.ps1 に反映したら、このスクリプトは削除する。

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

# バイナリファイルからメールアドレス形式の文字列を拾う（表示用。形式は非公開のため取れないこともある）
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
Write-Host "Teams のようこそ画面に残るアカウントが、どこに保存されているかを調べます。"

# ---- 1. PC 自体の参加状態 ----
# ここが YES だと、アカウントは「PC の参加情報」として登録されているため
# ファイル削除では消えず、設定アプリからの切断（または管理者対応）が必要になる。
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

# ---- 2. WAM（AAD BrokerPlugin）のアカウント ----
# cleanup.ps1 が削除している場所。ここが残っている場合は削除が失敗している。
Write-Section 2 'Windows のアカウント登録（WAM / cleanup.ps1 の削除対象）'
$wam = "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts"
$wamFiles = @(Get-ChildItem -Path $wam -Recurse -File -Force -ErrorAction SilentlyContinue)
if ($wamFiles.Count -gt 0) {
  Write-Found "$($wamFiles.Count) 件（cleanup.ps1 の削除が効いていない可能性があります）"
  foreach ($f in $wamFiles) {
    $mails = Get-EmailsFromFile $f.FullName
    if ($mails.Count -gt 0) { $mails | ForEach-Object { Write-Info "- $_" } } else { Write-Info "- $($f.Name)" }
  }
  $Hits += 2
} else {
  Write-None 'WAM のアカウント情報はありません'
}

# ---- 3. TokenBroker キャッシュ ----
Write-Section 3 'TokenBroker キャッシュ'
$tbc = @(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\TokenBroker\Cache" -File -Force -ErrorAction SilentlyContinue)
if ($tbc.Count -gt 0) {
  Write-Found "$($tbc.Count) 件のキャッシュファイル"
  $Hits += 3
} else {
  Write-None 'TokenBroker キャッシュはありません'
}

# ---- 4. IdentityCRL（保存済みID） ----
# Microsoft のサインイン基盤がアカウント名（UPN）を保存する場所。
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

# ---- 6. OneAuth ----
# 新しい Teams / Office が共通で使うアカウント保管庫。cleanup.ps1 では未対応。
Write-Section 6 'OneAuth（Teams・Office 共通のアカウント保管庫）'
$oneauth = @(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\OneAuth" -Recurse -File -Force -ErrorAction SilentlyContinue)
if ($oneauth.Count -gt 0) {
  Write-Found "$($oneauth.Count) 件のファイル"
  $mails = @()
  foreach ($f in ($oneauth | Select-Object -First 30)) { $mails += Get-EmailsFromFile $f.FullName }
  $mails = @($mails | Select-Object -Unique)
  if ($mails.Count -gt 0) { $mails | ForEach-Object { Write-Info "- $_" } } else { Write-Info '- アカウント名は取り出せませんでした（ファイルのみ存在）' }
  $Hits += 6
} else {
  Write-None 'OneAuth にアカウント情報はありません'
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

# ---- 8. cleanup.ps1 が効いているかの確認 ----
# ここが「残っている」なら、そもそもクリーンアップが実行されていない／失敗している。
Write-Section 8 'cleanup.ps1 の Teams・Outlook 削除が効いているか'
$appData = @(
  "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache",
  "$env:APPDATA\Microsoft\Teams",
  "$env:LOCALAPPDATA\Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe\LocalCache",
  "$env:LOCALAPPDATA\Microsoft\Outlook",
  "$env:APPDATA\Microsoft\Outlook"
)
$left = @($appData | Where-Object { Test-Path $_ })
if ($left.Count -gt 0) {
  Write-Found "$($left.Count) 件のアプリデータが残っています"
  $left | ForEach-Object { Write-Info "- $_" }
  $Hits += 8
} else {
  Write-None 'Teams・Outlook のアプリデータは削除済みです'
}

# ---- まとめ ----
Write-Host ""
Write-Host "=== まとめ ===" -ForegroundColor Cyan
$Hits = @($Hits | Sort-Object -Unique)
if ($Hits.Count -eq 0) {
  Write-Host "  アカウントの残骸は見つかりませんでした。" -ForegroundColor Green
  Write-Host "  それでもようこそ画面にアカウントが出る場合は、画面に出ているアカウント名を控えてください。"
} else {
  Write-Host "  アカウント情報が残っている項目: $($Hits -join ', ')" -ForegroundColor Red
  Write-Host "  → この番号（と、下の対処の要否）を控えて連絡してください。番号だけで原因の切り分けができます。"
  Write-Host ""
  Write-Host "  【番号ごとの意味】"
  if ($Hits -contains 1) { Write-Host "   1: PC 自体が職場アカウントに参加。設定 → アカウント → メールとアカウント から切断が必要（スクリプトでは消せない）" }
  if ($Hits -contains 2) { Write-Host "   2: cleanup.ps1 の削除対象が残っている。権限不足かファイルのロックで失敗している可能性" }
  if ($Hits -contains 3) { Write-Host "   3: TokenBroker キャッシュ。cleanup.ps1 に削除処理を追加すれば消せる" }
  if ($Hits -contains 4) { Write-Host "   4: IdentityCRL。ここにアカウント名が残る。cleanup.ps1 に削除処理を追加すれば消せる" }
  if ($Hits -contains 5) { Write-Host "   5: IdentityStore キャッシュ。Windows のサインイン情報側に残っている" }
  if ($Hits -contains 6) { Write-Host "   6: OneAuth。新しい Teams のようこそ画面の候補元として有力。cleanup.ps1 に削除処理を追加すれば消せる" }
  if ($Hits -contains 7) { Write-Host "   7: WorkplaceJoin 登録。設定 → アカウント → メールとアカウント から切断が必要" }
  if ($Hits -contains 8) { Write-Host "   8: そもそも Teams・Outlook のクリーンアップが実行されていない／失敗している" }
}
Write-Host ""
Write-Host "  ※ このスクリプトは何も削除していません。調査後は本体を削除してください:"
Write-Host '     Remove-Item "$env:TEMP\diag-accounts.ps1" -ErrorAction SilentlyContinue'
