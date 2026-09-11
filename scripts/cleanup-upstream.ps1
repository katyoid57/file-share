# 研修PCクリーンアップ（上流工程研修に固有の分）
# 実行: powershell -ExecutionPolicy Bypass -File .\cleanup-upstream.ps1          … クリーンアップ（削除）を行い、完了後に確認（-Check 相当）も自動実行する
# 確認: powershell -ExecutionPolicy Bypass -File .\cleanup-upstream.ps1 -Check   … 確認のみ（read-only。何度でも安全に実行可）
#   Claude デスクトップアプリのサインイン情報・会話履歴、Claude Code の設定と履歴、
#   配布フォルダ（デスクトップ直下・ユーザーフォルダ直下）、Git Bash の個人痕跡（.bash_history・.gitconfig 等）、
#   LibreOffice のユーザープロファイル（最近使ったドキュメントを含む）、Python・Node.js のキャッシュと対話履歴、
#   Windows のファイル履歴（最近使ったドキュメント・開く/保存ダイアログ）を対象にする。
#   ※ 受講者がサインインしていた Windows アカウントで実行すること（別アカウントで実行すると何も消えない）。
#   ※ 管理者権限は不要。
#   ※ ブラウザ・Zoom・Teams・Outlook・Office・資格情報・ダウンロード・ごみ箱は cleanup.ps1（共通）が担当する。
#   ※ ツール本体（Git・Python・Node.js・LibreOffice・Claude デスクトップアプリ）は削除しない。
#   ※ Windows PowerShell 5.1 で動作する範囲で書いている。
param([switch]$Check)

$ErrorActionPreference = 'Continue'

# 削除対象。Name は表示名、Paths は中身ごと消すフォルダ・ファイル。
# ※ Claude デスクトップアプリと Claude Code の保存先は実機で確認していない。存在するものだけを消す作りにしてある。
# Claude デスクトップアプリがユーザーデータを置くフォルダ。
# ※ %LOCALAPPDATA%\AnthropicClaude と %LOCALAPPDATA%\Claude は「アプリ本体の置き場」でもある（04 の
#    Get-ClaudeDesktop が実行ファイルを探す先）。ツリーごと消すと本体を壊すため、直下のデータ用サブ
#    フォルダだけを消す。どのフォルダができるかは実機で確認していないので、あるものだけを消す。
$ClaudeAppRoots = @(
  "$env:LOCALAPPDATA\AnthropicClaude",
  "$env:LOCALAPPDATA\Claude"
)
$ClaudeDataSubDirs = @(
  'Cache', 'Code Cache', 'GPUCache', 'DawnCache', 'Local Storage', 'Session Storage',
  'IndexedDB', 'Network', 'Cookies', 'Cookies-journal', 'Partitions', 'Crashpad', 'logs',
  'Service Worker', 'blob_storage', 'databases', 'sentry'
)
$ClaudeAppDataPaths = @("$env:APPDATA\Claude")
foreach ($root in $ClaudeAppRoots) {
  foreach ($sub in $ClaudeDataSubDirs) { $ClaudeAppDataPaths += (Join-Path $root $sub) }
}

$Targets = @(
  @{ Name = 'Claude デスクトップアプリのサインイン情報・キャッシュ';
     Paths = $ClaudeAppDataPaths },
  @{ Name = 'Claude Code の設定・会話履歴';
     Paths = @("$env:USERPROFILE\.claude", "$env:USERPROFILE\.claude.json", "$env:USERPROFILE\.claude.json.backup") },
  @{ Name = 'Git Bash の個人痕跡（コマンド履歴・git 設定）';
     Paths = @("$env:USERPROFILE\.bash_history", "$env:USERPROFILE\.gitconfig", "$env:USERPROFILE\.git-credentials") },
  @{ Name = 'LibreOffice のユーザープロファイル（最近使ったドキュメントを含む）';
     Paths = @("$env:APPDATA\LibreOffice") },
  @{ Name = 'Python・Node.js のキャッシュと対話履歴';
     Paths = @("$env:LOCALAPPDATA\pip\Cache", "$env:LOCALAPPDATA\npm-cache", "$env:APPDATA\npm-cache",
               "$env:USERPROFILE\.python_history", "$env:USERPROFILE\.node_repl_history") }
)

# Windows 側に残るファイル履歴（開く／保存ダイアログと最近使ったドキュメント）。
# LibreOffice 側の履歴だけ消しても、ここに成果物のファイル名とパスが残る。
$HistoryRegKeys = @(
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU'
)

# 配布フォルダの探し先。研修資料はデスクトップ直下、またはユーザーフォルダ直下に置かれる。
$HandoutRoots = @(
  [Environment]::GetFolderPath('Desktop'),
  $env:USERPROFILE
)

# 配布フォルダかどうかの判定には使わず、ユーザーフォルダ直下の標準フォルダを候補から外すために使う。
$StandardUserDirs = @(
  'Desktop', 'Documents', 'Downloads', 'Music', 'Pictures', 'Videos', 'Favorites', 'Links',
  'Contacts', 'Searches', 'Saved Games', 'AppData', 'Application Data',
  '3D Objects', 'ローカル設定', 'スタート メニュー', 'マイ ドキュメント', 'マイ ビデオ',
  'マイ ピクチャ', 'マイ ミュージック', 'Local Settings', 'My Documents', 'My Music',
  'My Pictures', 'My Videos', 'Start Menu', 'Recent',
  'NetHood', 'PrintHood', 'SendTo', 'Templates', 'Cookies', 'IntelGraphicsProfiles',
  'MicrosoftEdgeBackups', 'source', '.vscode'
)

# 法人テナントの同期フォルダは 'OneDrive - <会社名>' という名前になるため、前方一致で除外する。
# ここを取り違えて削除すると会社の OneDrive ごと消える。
$StandardUserDirPrefixes = @('OneDrive')

# 研修で作られたと思われるフォルダ・ファイルを列挙する（削除はしない）。
function Get-HandoutCandidates {
  $items = @()
  foreach ($root in ($HandoutRoots | Select-Object -Unique)) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    $found = Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -ne 'desktop.ini' -and $_.Name -notlike '.*' } |
      # ジャンクション（'My Documents' 等の互換用リンク）は、消すと実体まで巻き込むため候補にしない
      Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }
    if ($root -eq $env:USERPROFILE) {
      $found = $found | Where-Object {
        $name = $_.Name
        ($StandardUserDirs -notcontains $name) -and
        (-not ($StandardUserDirPrefixes | Where-Object { $name -like "$_*" }))
      }
    }
    $items += @($found)
  }
  return $items
}

# ユーザーフォルダ直下の隠しファイル（.claude.json.backup・.npmrc など）を列挙する。
# 名前を決め打ちしていないものが「消えないうえに見えない」状態にならないよう、点検で目に入れる。
function Get-DotFiles {
  $known = @('.claude', '.claude.json', '.claude.json.backup', '.bash_history', '.gitconfig',
             '.git-credentials', '.python_history', '.node_repl_history')
  return @(Get-ChildItem -LiteralPath $env:USERPROFILE -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like '.*' -and $known -notcontains $_.Name })
}

# ===== 確認モード（-Check）: 残っていないかを確認する（read-only）=====
function Invoke-Check {
  Write-Host '=== クリーンアップ確認（上流工程研修の固有分）===' -ForegroundColor Cyan
  Write-Host ''

  $ng = 0
  foreach ($t in $Targets) {
    $left = @($t.Paths | Where-Object { Test-Path -LiteralPath $_ })
    if ($left.Count -eq 0) {
      Write-Host "[OK] $($t.Name): 残っていません" -ForegroundColor Green
    } else {
      $ng++
      Write-Host "[NG] $($t.Name): 残っています" -ForegroundColor Red
      $left | ForEach-Object { Write-Host "     $_" }
    }
  }

  # Windows 側のファイル履歴
  $leftKeys = @($HistoryRegKeys | Where-Object { Test-Path -LiteralPath $_ })
  if ($leftKeys.Count -eq 0) {
    Write-Host '[OK] Windows のファイル履歴（最近使ったドキュメント・開く/保存の履歴）: 残っていません' -ForegroundColor Green
  } else {
    $ng++
    Write-Host '[NG] Windows のファイル履歴が残っています' -ForegroundColor Red
    $leftKeys | ForEach-Object { Write-Host "     $_" }
  }

  # Windows 資格情報に Claude 名義のものが残っていないか
  $cred = cmdkey /list 2>$null | Select-String -Pattern 'Claude' -SimpleMatch
  if (-not $cred) {
    Write-Host '[OK] Windows 資格情報: Claude 名義のものはありません' -ForegroundColor Green
  } else {
    $ng++
    Write-Host '[NG] Windows 資格情報に Claude 名義のものがあります（コントロールパネル → 資格情報マネージャー から削除してください）' -ForegroundColor Red
    $cred | ForEach-Object { Write-Host "     $_" }
  }

  # ツール本体が消えていないか（消しすぎの検知）
  Write-Host ''
  foreach ($t in @(@{N='Git';C='git'}, @{N='Python';C='python'}, @{N='Node.js';C='node'})) {
    if (Get-Command $t.C -CommandType Application -ErrorAction SilentlyContinue) {
      Write-Host "[OK] $($t.N) は残っています" -ForegroundColor Green
    } else {
      $ng++; Write-Host "[NG] $($t.N) が見つかりません（ツール本体は残す対象です）" -ForegroundColor Red
    }
  }
  $soffice = @("$env:ProgramFiles\LibreOffice\program\soffice.exe", "${env:ProgramFiles(x86)}\LibreOffice\program\soffice.exe") |
    Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
  if ($soffice) {
    Write-Host '[OK] LibreOffice は残っています' -ForegroundColor Green
  } else {
    $ng++; Write-Host '[NG] LibreOffice が見つかりません（ツール本体は残す対象です）' -ForegroundColor Red
  }
  $claudeExe = @("$env:LOCALAPPDATA\AnthropicClaude\claude.exe", "$env:LOCALAPPDATA\Programs\Claude\Claude.exe", "$env:ProgramFiles\Claude\Claude.exe") |
    Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if ($claudeExe) {
    Write-Host "[OK] Claude デスクトップアプリは残っています（$claudeExe）" -ForegroundColor Green
  } else {
    $ng++; Write-Host '[NG] Claude デスクトップアプリの実行ファイルが見つかりません（本体は残す対象です）' -ForegroundColor Red
  }

  # 配布フォルダは名前が分からないため、候補を一覧表示する（合否判定はしない）
  Write-Host ''
  $cands = Get-HandoutCandidates
  if (-not $cands) {
    Write-Host '[情報] デスクトップ・ユーザーフォルダ直下: 標準のフォルダ以外は見当たりません（ドキュメント・ピクチャ・OneDrive 配下は別に確認してください）'
  } else {
    Write-Host '[情報] デスクトップ・ユーザーフォルダ直下に次の項目があります（配布フォルダや受講者が作ったファイルが無いか確認してください）'
    $cands | ForEach-Object { Write-Host "     $($_.FullName)" }
  }

  # 決め打ちしていない隠しファイル
  $dots = Get-DotFiles
  if ($dots.Count -gt 0) {
    Write-Host '[情報] ユーザーフォルダ直下に次の隠し項目があります（研修で作られたものが無いか確認してください）'
    $dots | ForEach-Object { Write-Host "     $($_.FullName)" }
  }

  Write-Host ''
  if ($ng -eq 0) {
    Write-Host '=== 確認完了: 対象はすべて削除済みです ===' -ForegroundColor Green
  } else {
    Write-Host "=== 確認完了: [NG] が $ng 件あります ===" -ForegroundColor Red
    Write-Host 'アプリが起動しているとファイルを掴んで削除できません。Claude デスクトップアプリ・LibreOffice・Git Bash を終了してから、もう一度クリーンアップを実行してください。'
  }
  Write-Host ''
  Write-Host '※ ブラウザ・Zoom・Teams・Outlook・Office・資格情報・ダウンロード・ごみ箱は cleanup.ps1（共通）で確認します。'
}

# ===== 実行モード: 削除する =====
function Invoke-Cleanup {
  # 1. ファイルを掴んでいるアプリを終了する
  Write-Host ''
  Write-Host '=== 対象アプリの終了 ===' -ForegroundColor Cyan
  # OneDrive は同期でファイルを掴む／削除後に戻すことがあるため一緒に終了する（次回サインイン時に自動起動する）
  foreach ($proc in @('claude', 'soffice', 'soffice.bin', 'bash', 'mintty', 'OneDrive')) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
      Write-Host "  $proc を終了します。"
      Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
  }
  Start-Sleep -Seconds 2

  # 2. 対象の削除
  foreach ($t in $Targets) {
    Write-Host ''
    Write-Host "=== $($t.Name) の削除 ===" -ForegroundColor Cyan
    $hit = $false
    foreach ($p in $t.Paths) {
      if (-not (Test-Path -LiteralPath $p)) { continue }
      $hit = $true
      Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path -LiteralPath $p) {
        Write-Host "  削除に失敗しました: $p" -ForegroundColor Red
        Write-Host '    アプリが起動しているか、階層が深くパスが長すぎる可能性があります。アプリを終了して再実行し、それでも残る場合はエクスプローラーで手動削除してください。'
      } else {
        Write-Host "  削除しました: $p"
      }
    }
    if (-not $hit) { Write-Host '  対象がありません（未使用または削除済み）。' }
  }

  # 3. Windows 側のファイル履歴（開く／保存ダイアログと最近使ったドキュメント）
  Write-Host ''
  Write-Host '=== Windows のファイル履歴の削除 ===' -ForegroundColor Cyan
  foreach ($k in $HistoryRegKeys) {
    if (Test-Path -LiteralPath $k) {
      Remove-Item -LiteralPath $k -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path -LiteralPath $k) {
        Write-Host "  削除に失敗しました: $k" -ForegroundColor Red
      } else {
        Write-Host "  削除しました: $k"
      }
    } else {
      Write-Host "  対象がありません: $k"
    }
  }

  # 4. 配布フォルダ（1件ずつ名前を確認して削除する）
  Write-Host ''
  Write-Host '=== 配布フォルダ・研修で作られたファイルの削除 ===' -ForegroundColor Cyan
  $cands = Get-HandoutCandidates
  if (-not $cands) {
    Write-Host '  対象がありません。'
  } else {
    foreach ($c in $cands) {
      $ans = Read-Host "  削除しますか？ $($c.FullName) [y/N]"
      if ($ans -eq 'y' -or $ans -eq 'Y') {
        Remove-Item -LiteralPath $c.FullName -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $c.FullName) {
          Write-Host "    削除に失敗しました: $($c.FullName)" -ForegroundColor Red
        } else {
          Write-Host "    削除しました: $($c.FullName)"
        }
      } else {
        Write-Host "    スキップしました: $($c.FullName)"
      }
    }
  }

  Write-Host ''
  # 5. 決め打ちしていない隠しファイルの提示（削除はしない）
  $dots = Get-DotFiles
  if ($dots.Count -gt 0) {
    Write-Host ''
    Write-Host '=== ユーザーフォルダ直下の隠し項目（参考表示。削除はしません）===' -ForegroundColor Cyan
    $dots | ForEach-Object { Write-Host "  $($_.FullName)" }
    Write-Host '  研修で作られたものがあれば、名前を確認して手動で削除してください。'
  }

  Write-Host ''
  Write-Host '=== 上流工程研修の固有分のクリーンアップ完了 ===' -ForegroundColor Green
  Write-Host '続けて、共通分（ブラウザ・Zoom・Teams・Outlook・Office・資格情報・ダウンロード・ごみ箱）を cleanup.ps1 で実施してください。' -ForegroundColor Yellow
}

# ===== エントリポイント =====
if ($Check) {
  Invoke-Check
} else {
  Write-Host 'これは「クリーンアップ実行」です（削除を行います）。確認だけなら -Check を付けてください。' -ForegroundColor Yellow
  Write-Host 'Claude デスクトップアプリ・LibreOffice・Git Bash は自動で終了します（未保存の内容は失われます）。'
  $ans = Read-Host 'クリーンアップを実行しますか？ [y/N]'
  if ($ans -ne 'y' -and $ans -ne 'Y') {
    Write-Host '中止しました。確認のみは -Check を付けて実行できます。'
    return
  }
  Invoke-Cleanup

  # 削除に続けて確認（-Check 相当）を自動実行する（read-only）
  Write-Host ''
  Write-Host '続けて確認を行います（-Check と同じ内容）。' -ForegroundColor Cyan
  Write-Host ''
  Invoke-Check
}
