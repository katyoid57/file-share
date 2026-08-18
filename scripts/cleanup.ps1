# 研修PCクリーンアップ（Windows側）
# 実行: powershell -ExecutionPolicy Bypass -File .\cleanup.ps1          … クリーンアップ（削除）を行い、完了後に確認（-Check 相当）も自動実行する
# 確認: powershell -ExecutionPolicy Bypass -File .\cleanup.ps1 -Check   … 確認のみ（read-only。何度でも安全に実行可）
#   ブラウザ(Chrome/Edge)のCookie・履歴・ブックマーク・タブ削除、メモ帳の未保存タブ削除、Zoom のログイン情報削除、
#   Teams・Outlook のログイン情報削除、Office のサインイン解除、Windows 資格情報・職場アカウントの削除、
#   ダウンロードフォルダの全削除、ピクチャのスクリーンショット削除、エクスプローラーの履歴削除、
#   C:\ 直下の非標準フォルダの確認・削除、ごみ箱を空にする。
param([switch]$Check)

$ErrorActionPreference = 'Continue'

# C:\ 直下に標準で存在するフォルダ。これ以外を「研修生が作成した可能性がある非標準フォルダ」として
# 検知する（-Check では列挙のみ、実行時は 1 件ずつ確認して削除する）。
# ※ $ を含む名前はシングルクォートで囲みリテラル扱いにする。
$StandardRootDirs = @(
  'Windows', 'Program Files', 'Program Files (x86)', 'ProgramData', 'Users', 'PerfLogs',
  'Recovery', '$Recycle.Bin', 'System Volume Information', '$WinREAgent', '$SysReset',
  'OneDriveTemp', 'Intel', 'Drivers', 'AMD', 'NVIDIA', 'Config.Msi', 'Documents and Settings',
  'inetpub', 'Quarantine', 'SWSetup'
)

# Teams・Outlook のログイン情報の置き場所。新しい版（MSIX パッケージ）と従来版で場所が違うため両方を対象にする。
#   Root … アプリが使われた痕跡（無ければ「未インストール／未使用」と判定する。削除はしない）
#   Data … ログイン情報・アカウントキャッシュ本体（削除対象）
# ※ 新しい Teams / Outlook はパッケージ本体を残し LocalCache だけ消す（次回起動時に再作成され、ログイン画面から始まる）。
# ※ 従来版 Outlook の LOCALAPPDATA 配下は .ost（受信メール本体のキャッシュ）、APPDATA 配下は署名・送信設定。
$LoginDataTargets = @(
  @{ Name = 'Teams（新しい Teams）';
     Root = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe";
     Data = @("$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache") },
  @{ Name = 'Teams（従来版）';
     Root = "$env:LOCALAPPDATA\Microsoft\Teams";
     Data = @("$env:APPDATA\Microsoft\Teams") },
  @{ Name = 'Outlook（新しい Outlook）';
     Root = "$env:LOCALAPPDATA\Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe";
     Data = @("$env:LOCALAPPDATA\Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe\LocalCache") },
  @{ Name = 'Outlook（従来版）';
     Root = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE';
     Data = @("$env:LOCALAPPDATA\Microsoft\Outlook", "$env:APPDATA\Microsoft\Outlook") }
)

# Windows の「職場または学校アカウント」（設定 → アカウント → メールとアカウント）のトークンキャッシュ。
# ここが残っていると Teams/Outlook のデータを消しても次回起動時に同じアカウントが候補表示される。
$TokenBrokerAccounts = "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts"

# HKCU の Office バージョンキー（16.0 等）を列挙する。Office 2016 以降は 16.0 だが、
# 環境によって複数のバージョンキーが残っていることがあるため数値バージョンをすべて対象にする。
function Get-OfficeVersionNames {
  Get-ChildItem 'HKCU:\Software\Microsoft\Office' -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match '^\d+\.\d+$' } |
    ForEach-Object { $_.PSChildName }
}

# 従来版 Outlook のプロファイル関連レジストリキー（メールアドレス・アカウント設定・接続先）を列挙する。
function Get-OutlookProfileKeys {
  $keys = @()
  foreach ($ver in (Get-OfficeVersionNames)) {
    foreach ($sub in @('Outlook\Profiles', 'Outlook\AutoDiscover')) {
      $p = "HKCU:\Software\Microsoft\Office\$ver\$sub"
      if (Test-Path $p) { $keys += $p }
    }
  }
  $keys
}

# Office アプリ（Word/Excel 等）のサインイン情報が入るレジストリキーを列挙する。
function Get-OfficeIdentityKeys {
  $keys = @()
  foreach ($ver in (Get-OfficeVersionNames)) {
    $p = "HKCU:\Software\Microsoft\Office\$ver\Common\Identity"
    if (Test-Path $p) { $keys += $p }
  }
  $keys
}

# 資格情報マネージャーのうち Teams / Outlook / Office 関連のターゲット名だけを返す。
# cmdkey の出力は表示ロケールで見出しが変わるため、ターゲット名そのものを正規表現で拾う。
# 返す名前は cmdkey /delete: に渡せる形（先頭の "LegacyGeneric:target=" 等を落としたもの）にする。
function Get-OfficeCredentialTargets {
  $targets = @()
  foreach ($line in (cmdkey /list 2>$null)) {
    if ($line -match '((?:LegacyGeneric|Domain|WindowsLive|MicrosoftAccount):[^\s]+)') {
      $t = $Matches[1]
      if ($t -match 'MicrosoftOffice|Teams|Outlook') {
        $targets += ($t -replace '^[A-Za-z]+:target=', '')
      }
    }
  }
  $targets | Select-Object -Unique
}

# 職場アカウントのトークンキャッシュから、表示用のアカウント名（メールアドレス形式）を抜き出す。
# ファイル形式は非公開のため、取り出せない場合はファイル名を返す（表示専用。判定には使わない）。
function Get-TokenAccountNames {
  $names = @()
  foreach ($f in @(Get-ChildItem -Path $TokenBrokerAccounts -Recurse -File -Force -ErrorAction SilentlyContinue)) {
    $hit = @()
    try {
      $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
      $text = [Text.Encoding]::Unicode.GetString($bytes) + [Text.Encoding]::ASCII.GetString($bytes)
      $hit = @([regex]::Matches($text, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}') | ForEach-Object { $_.Value })
    } catch {
      $hit = @()
    }
    if ($hit.Count -gt 0) { $names += $hit } else { $names += $f.Name }
  }
  $names | Select-Object -Unique
}

# $LoginDataTargets のうち名前が $Prefix で始まるもの（Teams / Outlook）の Data パスを削除する。
# 削除できたかは Test-Path で確認する（アプリが起動中だとロックされて消えないため）。
function Remove-LoginData {
  param([string]$Prefix)
  $found = $false
  foreach ($t in ($LoginDataTargets | Where-Object { $_.Name -like "$Prefix*" })) {
    foreach ($p in $t.Data) {
      if (-not (Test-Path $p)) { continue }
      $found = $true
      Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path $p) {
        Write-Host "  削除に失敗しました（アプリが起動中の可能性。閉じてから再実行してください）: $p" -ForegroundColor Red
      } else {
        Write-Host "  削除しました: $($t.Name) - $p"
      }
    }
  }
  if (-not $found) {
    Write-Host "  スキップ: 削除対象のログイン情報はありません（未ログインまたは未インストール）。"
  }
}

# ===== 確認モード（-Check）: クリーンアップ済みかを確認する（read-only）=====
function Invoke-Check {
  Write-Host "=== クリーンアップ確認（Windows側）==="
  Write-Host ""

  # ダウンロードフォルダの確認
  $downloads = "$env:USERPROFILE\Downloads"
  $count = (Get-ChildItem -Path $downloads -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | Measure-Object).Count
  if ($count -eq 0) {
    Write-Host "[OK] ダウンロードフォルダ: 空です" -ForegroundColor Green
  } else {
    Write-Host "[NG] ダウンロードフォルダ: $count 項目が残っています" -ForegroundColor Red
  }

  # ピクチャのスクリーンショットの確認（Snipping Tool の自動保存・Win+PrtScn の保存先）
  $screenshots = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Screenshots'
  if (Test-Path $screenshots) {
    $shotCount = (Get-ChildItem -Path $screenshots -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | Measure-Object).Count
    if ($shotCount -eq 0) {
      Write-Host "[OK] スクリーンショット: ピクチャ内に残っていません" -ForegroundColor Green
    } else {
      Write-Host "[NG] スクリーンショット: $shotCount 項目が残っています" -ForegroundColor Red
    }
  } else {
    Write-Host "[--] スクリーンショット: フォルダがありません（保存されていません）" -ForegroundColor Yellow
  }

  # ブラウザデータの確認
  $browsers = @(
    @{ Name = 'Chrome'; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default" },
    @{ Name = 'Edge';   Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" }
  )
  foreach ($b in $browsers) {
    if (Test-Path $b.Path) {
      $cookie = (Test-Path (Join-Path $b.Path 'Network\Cookies')) -or (Test-Path (Join-Path $b.Path 'Cookies'))
      $history = Test-Path (Join-Path $b.Path 'History')
      $bookmark = Test-Path (Join-Path $b.Path 'Bookmarks')
      if (-not $cookie -and -not $history -and -not $bookmark) {
        Write-Host "[OK] $($b.Name): Cookie・履歴・ブックマーク削除済み" -ForegroundColor Green
      } else {
        Write-Host "[NG] $($b.Name): 一部データが残っています（Cookie/履歴/ブックマーク）" -ForegroundColor Red
      }
    } else {
      Write-Host "[--] $($b.Name): インストールされていません" -ForegroundColor Yellow
    }
  }

  # メモ帳の未保存タブの確認
  $notepadState = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState\TabState"
  $tabCount = (Get-ChildItem -Path $notepadState -Force -ErrorAction SilentlyContinue | Measure-Object).Count
  if ($tabCount -eq 0) {
    Write-Host "[OK] メモ帳: 未保存タブなし" -ForegroundColor Green
  } else {
    Write-Host "[NG] メモ帳: 未保存タブが残っています（$tabCount 件）" -ForegroundColor Red
  }

  # Zoom のログイン情報の確認
  $zoomData = "$env:APPDATA\Zoom\data"
  if (Test-Path "$env:APPDATA\Zoom") {
    if (Test-Path $zoomData) {
      Write-Host "[NG] Zoom: ログイン情報が残っています" -ForegroundColor Red
    } else {
      Write-Host "[OK] Zoom: ログイン情報削除済み（再ログインが必要な状態）" -ForegroundColor Green
    }
  } else {
    Write-Host "[--] Zoom: 利用されていません（未ログインまたは未インストール）" -ForegroundColor Yellow
  }

  # Teams・Outlook のログイン情報の確認（新しい版／従来版で置き場所が違うため両方を見る）
  foreach ($t in $LoginDataTargets) {
    $left = @($t.Data | Where-Object { Test-Path $_ })
    if ($left.Count -gt 0) {
      Write-Host "[NG] $($t.Name): ログイン情報が残っています" -ForegroundColor Red
      $left | ForEach-Object { Write-Host "       - $_" }
    } elseif (Test-Path $t.Root) {
      Write-Host "[OK] $($t.Name): ログイン情報削除済み（再ログインが必要な状態）" -ForegroundColor Green
    } else {
      Write-Host "[--] $($t.Name): 利用されていません（未ログインまたは未インストール）" -ForegroundColor Yellow
    }
  }

  # 従来版 Outlook のプロファイル（メールアドレス・アカウント設定）の確認
  $profKeys = @(Get-OutlookProfileKeys)
  if ($profKeys.Count -gt 0) {
    Write-Host "[NG] Outlook プロファイル: アカウント設定が残っています（$($profKeys.Count) 件）" -ForegroundColor Red
    $profKeys | ForEach-Object { Write-Host "       - $_" }
  } else {
    Write-Host "[OK] Outlook プロファイル: 残っていません（削除済みまたは従来版 Outlook 未使用）" -ForegroundColor Green
  }

  # Office アプリ（Word/Excel 等）のサインイン情報の確認
  $idKeys = @(Get-OfficeIdentityKeys)
  if ($idKeys.Count -gt 0) {
    Write-Host "[NG] Office サインイン: アカウント情報が残っています（$($idKeys.Count) 件）" -ForegroundColor Red
    $idKeys | ForEach-Object { Write-Host "       - $_" }
  } else {
    Write-Host "[OK] Office サインイン: 残っていません（サインアウト済みまたは Office 未インストール）" -ForegroundColor Green
  }

  # Windows 資格情報マネージャー（Teams/Outlook/Office 関連）の確認
  $creds = @(Get-OfficeCredentialTargets)
  if ($creds.Count -gt 0) {
    Write-Host "[NG] Windows 資格情報: Teams/Outlook/Office の資格情報が残っています（$($creds.Count) 件）" -ForegroundColor Red
    $creds | ForEach-Object { Write-Host "       - $_" }
  } else {
    Write-Host "[OK] Windows 資格情報: Teams/Outlook/Office の資格情報はありません" -ForegroundColor Green
  }

  # Windows「職場または学校アカウント」（設定 → アカウント → メールとアカウント）の確認
  $tokenItems = @(Get-ChildItem -Path $TokenBrokerAccounts -Recurse -File -Force -ErrorAction SilentlyContinue)
  if ($tokenItems.Count -gt 0) {
    Write-Host "[NG] 職場または学校アカウント: サインイン情報が残っています" -ForegroundColor Red
    Get-TokenAccountNames | ForEach-Object { Write-Host "       - $_" }
    Write-Host "       → クリーンアップ実行で削除できます。それでも設定アプリの一覧に残る場合は" -ForegroundColor Red
    Write-Host "         設定 → アカウント → メールとアカウント から該当アカウントを「切断」してください。" -ForegroundColor Red
  } else {
    Write-Host "[OK] 職場または学校アカウント: サインイン情報はありません" -ForegroundColor Green
  }

  # エクスプローラー履歴の確認（最近使ったファイル・クイックアクセス・検索/アドレスバー履歴）
  $recent = "$env:APPDATA\Microsoft\Windows\Recent"
  $recentCount = 0
  foreach ($sub in @('', 'AutomaticDestinations', 'CustomDestinations')) {
    $p = if ($sub) { Join-Path $recent $sub } else { $recent }
    if (Test-Path $p) {
      $recentCount += (Get-ChildItem -Path $p -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    }
  }
  $ww = Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery' -ErrorAction SilentlyContinue
  $tp = Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths' -ErrorAction SilentlyContinue
  $wwCount = if ($ww) { ($ww.Property | Measure-Object).Count } else { 0 }
  $tpCount = if ($tp) { ($tp.Property | Measure-Object).Count } else { 0 }
  if ($recentCount -eq 0 -and $wwCount -eq 0 -and $tpCount -eq 0) {
    Write-Host "[OK] エクスプローラー履歴: 最近使ったファイル・検索/アドレスバー履歴なし" -ForegroundColor Green
  } else {
    Write-Host "[NG] エクスプローラー履歴: 残っています（最近使った $recentCount 件 / 検索 $wwCount 件 / アドレス $tpCount 件）" -ForegroundColor Red
  }

  # C:\ 直下の非標準フォルダの確認（研修生が C:\ 直下に作成した可能性。参考表示のみ。削除はしない）
  Write-Host ""
  Write-Host "[情報] C:\ 直下の標準以外のフォルダ（研修生が作成した可能性。あればクリーンアップ実行で 1 件ずつ削除できます）:" -ForegroundColor Yellow
  $rootDirs = Get-ChildItem -Path 'C:\' -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $StandardRootDirs -notcontains $_.Name }
  if ($rootDirs) {
    $rootDirs | ForEach-Object { Write-Host "       - C:\$($_.Name)" }
  } else {
    Write-Host "       （ありません）"
  }

  # デスクトップ / ドキュメント / ピクチャ のファイル・フォルダ一覧（参考表示のみ。判定はしない。
  # ショートカットに限らず全項目を表示する。セットアップ手順以外があれば手動で削除する）
  # -Force を付けないので隠しファイル・システムファイル（desktop.ini 等）は除外される
  $listDirs = @(
    @{ Name = 'デスクトップ';   Path = [Environment]::GetFolderPath('Desktop') },
    @{ Name = 'ドキュメント';   Path = [Environment]::GetFolderPath('MyDocuments') },
    @{ Name = 'ピクチャ';       Path = [Environment]::GetFolderPath('MyPictures') }
  )
  foreach ($d in $listDirs) {
    Write-Host ""
    Write-Host "[情報] $($d.Name) にあるファイル・フォルダ（隠しファイルを除く。手順以外があれば手動削除）:" -ForegroundColor Yellow
    $items = Get-ChildItem -Path $d.Path -ErrorAction SilentlyContinue
    if ($items) {
      foreach ($i in $items) {
        if ($i.PSIsContainer) { Write-Host "       - $($i.Name)/" } else { Write-Host "       - $($i.Name)" }
      }
    } else {
      Write-Host "       （ありません）"
    }
  }

  Write-Host ""
  Write-Host "=== 確認完了 ==="
}

# ===== 実行モード: クリーンアップ（削除）を行う =====
function Invoke-Cleanup {
  # 1. ブラウザ・メモ帳・Zoom・Teams・Outlook を終了する
  #    （プロファイル/未保存タブ/ログイン情報のロックを外すため。-Force で未保存内容ごと閉じる）
  #    ms-teams=新しい Teams / Teams=従来版 Teams / olk=新しい Outlook / OUTLOOK=従来版 Outlook
  Write-Host "=== ブラウザ・メモ帳・Zoom・Teams・Outlook を終了します ===" -ForegroundColor Cyan
  foreach ($name in @('chrome', 'msedge', 'notepad', 'Zoom', 'ms-teams', 'Teams', 'olk', 'OUTLOOK')) {
    Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  }
  Start-Sleep -Seconds 2

  # 2. Cookie・閲覧履歴・ブックマークを削除する
  Write-Host ""
  Write-Host "=== ブラウザの Cookie・閲覧履歴・ブックマーク・タブ/セッションを削除します ===" -ForegroundColor Cyan
  $browsers = @(
    @{ Name = 'Chrome'; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default" },
    @{ Name = 'Edge';   Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" }
  )
  $targets = @(
    'Network\Cookies', 'Cookies', 'History', 'Bookmarks', 'Bookmarks.bak',
    'Current Session', 'Current Tabs', 'Last Session', 'Last Tabs',  # 開いていた/前回のタブ
    'Sessions',                                                       # 最近閉じたタブの履歴（フォルダ）
    'Top Sites', 'Visited Links'                                      # 新しいタブの「よく使うサイト」等
  )
  foreach ($b in $browsers) {
    if (Test-Path $b.Path) {
      foreach ($t in $targets) {
        $f = Join-Path $b.Path $t
        if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue }
      }
      Write-Host "  クリア: $($b.Name)"
    } else {
      Write-Host "  スキップ: $($b.Name) はインストールされていません"
    }
  }
  Write-Host "  ※ サーバー側セッション無効化のため、事前に claude.ai / GitHub を手動ログアウトしておくと確実です。"

  # 3. メモ帳の未保存タブを削除する（Windows 11 のメモ帳はセッション復元で未保存内容を保持するため）
  Write-Host ""
  Write-Host "=== メモ帳の未保存タブを削除します ===" -ForegroundColor Cyan
  $notepadState = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState\TabState"
  if (Test-Path $notepadState) {
    Get-ChildItem -Path $notepadState -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  メモ帳の未保存タブ情報をクリアしました。"
  } else {
    Write-Host "  メモ帳の未保存タブはありません（または対象外のメモ帳）。"
  }

  # 4. Zoom のログイン情報を削除する（自動ログイン用トークン等。次回起動時に再ログインが必要＝ログアウト状態になる）
  Write-Host ""
  Write-Host "=== Zoom のログイン情報を削除します ===" -ForegroundColor Cyan
  $zoomData = "$env:APPDATA\Zoom\data"
  if (Test-Path $zoomData) {
    Remove-Item $zoomData -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Zoom のログイン情報・ローカルデータをクリアしました（次回起動時に再ログインが必要になります）。"
  } else {
    Write-Host "  スキップ: Zoom のログイン情報はありません（未ログインまたは未インストール）。"
  }

  # 5. Teams のログイン情報を削除する（新しい Teams・従来版 Teams の両方。次回起動時はサインイン画面から始まる）
  Write-Host ""
  Write-Host "=== Teams のログイン情報を削除します ===" -ForegroundColor Cyan
  Remove-LoginData 'Teams'

  # 6. Outlook のログイン情報・プロファイルを削除する
  #    新しい Outlook はパッケージのキャッシュ、従来版はデータファイル（.ost）と署名、
  #    さらにアカウント設定がレジストリのプロファイルに残るため、あわせて削除する。
  Write-Host ""
  Write-Host "=== Outlook のログイン情報・プロファイルを削除します ===" -ForegroundColor Cyan
  Remove-LoginData 'Outlook'
  $profKeys = @(Get-OutlookProfileKeys)
  if ($profKeys.Count -gt 0) {
    foreach ($k in $profKeys) {
      Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path $k) {
        Write-Host "  削除に失敗しました（Outlook が起動中の可能性）: $k" -ForegroundColor Red
      } else {
        Write-Host "  削除しました: $k"
      }
    }
  } else {
    Write-Host "  スキップ: Outlook のプロファイル（アカウント設定）はありません。"
  }

  # 7. Office アプリ（Word/Excel 等）のサインイン情報を削除する
  #    ※ Office が受講者のアカウントでライセンス認証されている場合、サインアウトで未ライセンス状態になる。
  #      次の受講者が自分のアカウントでサインインし直す想定。Office 未インストールならスキップされる。
  Write-Host ""
  Write-Host "=== Office のサインイン情報を削除します ===" -ForegroundColor Cyan
  $idKeys = @(Get-OfficeIdentityKeys)
  if ($idKeys.Count -gt 0) {
    foreach ($k in $idKeys) {
      Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path $k) {
        Write-Host "  削除に失敗しました（Office アプリが起動中の可能性）: $k" -ForegroundColor Red
      } else {
        Write-Host "  削除しました: $k"
      }
    }
    Write-Host "  ※ Office アプリは次回起動時にサインアウト状態になります。"
  } else {
    Write-Host "  スキップ: Office のサインイン情報はありません（サインアウト済みまたは Office 未インストール）。"
  }

  # 8. Windows 資格情報マネージャーから Teams/Outlook/Office の資格情報を削除する
  #    （ここが残っていると、アプリのデータを消しても再入力なしでサインインできてしまう）
  Write-Host ""
  Write-Host "=== Windows 資格情報（Teams/Outlook/Office）を削除します ===" -ForegroundColor Cyan
  $creds = @(Get-OfficeCredentialTargets)
  if ($creds.Count -gt 0) {
    foreach ($c in $creds) {
      cmdkey /delete:$c > $null 2>&1
      if ($LASTEXITCODE -eq 0) {
        Write-Host "  削除しました: $c"
      } else {
        Write-Host "  削除に失敗しました（手動で確認してください）: $c" -ForegroundColor Red
      }
    }
    Write-Host "  ※ 残りは「コントロールパネル → ユーザーアカウント → 資格情報マネージャー」で確認できます。"
  } else {
    Write-Host "  スキップ: Teams/Outlook/Office の資格情報はありません。"
  }

  # 9. Windows の「職場または学校アカウント」のサインイン情報を削除する
  #    設定 → アカウント → メールとアカウント に残る登録。消さないと次回起動時に
  #    同じアカウントが候補表示され、ワンクリックでサインインできてしまう。
  #    ※ 消えるのはサインイン中ユーザーのトークンキャッシュのみで、PC のドメイン参加状態は解除されない。
  Write-Host ""
  Write-Host "=== Windows の職場または学校アカウントを削除します ===" -ForegroundColor Cyan
  $tokenItems = @(Get-ChildItem -Path $TokenBrokerAccounts -Recurse -File -Force -ErrorAction SilentlyContinue)
  if ($tokenItems.Count -gt 0) {
    Write-Host "  以下のアカウントのサインイン情報を削除します:"
    Get-TokenAccountNames | ForEach-Object { Write-Host "    - $_" }
    Get-ChildItem -Path $TokenBrokerAccounts -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $left = @(Get-ChildItem -Path $TokenBrokerAccounts -Recurse -File -Force -ErrorAction SilentlyContinue)
    if ($left.Count -gt 0) {
      Write-Host "  一部が削除できませんでした（$($left.Count) 件）。設定 → アカウント → メールとアカウント から「切断」してください。" -ForegroundColor Red
    } else {
      Write-Host "  削除しました。"
      Write-Host "  ※ 設定アプリの一覧に表示が残る場合は、設定 → アカウント → メールとアカウント から「切断」してください。"
    }
  } else {
    Write-Host "  スキップ: 職場または学校アカウントのサインイン情報はありません。"
  }

  # 10. ダウンロードフォルダの中身を全削除する
  Write-Host ""
  Write-Host "=== ダウンロードフォルダを空にします ===" -ForegroundColor Cyan
  $downloads = "$env:USERPROFILE\Downloads"
  # desktop.ini はフォルダの表示設定を保持するシステムファイルなので削除対象から除外する
  $items = Get-ChildItem -Path $downloads -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' }
  if ($items) {
    Write-Host "  以下の $($items.Count) 項目を削除します:"
    $items | ForEach-Object { Write-Host "    - $($_.Name)" }
    $confirm = Read-Host "ダウンロードフォルダの中身をすべて削除しますか？ [y/N]"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
      $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "  削除しました。"
    } else {
      Write-Host "  スキップしました。"
    }
  } else {
    Write-Host "  ダウンロードフォルダは既に空です。"
  }

  # 11. ピクチャのスクリーンショットを削除する（Snipping Tool の自動保存・Win+PrtScn の保存先）
  Write-Host ""
  Write-Host "=== ピクチャのスクリーンショットを削除します ===" -ForegroundColor Cyan
  $screenshots = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Screenshots'
  if (Test-Path $screenshots) {
    # desktop.ini はフォルダの表示設定を保持するシステムファイルなので削除対象から除外する
    $shots = Get-ChildItem -Path $screenshots -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' }
    if ($shots) {
      $shots | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "  ピクチャ内のスクリーンショット $($shots.Count) 項目を削除しました。"
    } else {
      Write-Host "  ピクチャ内にスクリーンショットはありません。"
    }
  } else {
    Write-Host "  スキップ: スクリーンショットフォルダはありません（保存されていません）。"
  }

  # 12. エクスプローラーの履歴を削除する（最近使ったファイル・クイックアクセス・検索/アドレスバー履歴）
  #    履歴ファイル（ジャンプリスト等）はエクスプローラー（シェル）が掴んでロックし、
  #    起動中は削除が失敗したり終了時に履歴を書き戻したりするため、
  #    先にエクスプローラーを終了 → 削除 → 起動し直す、の順で行う。
  Write-Host ""
  Write-Host "=== エクスプローラーの履歴を削除します ===" -ForegroundColor Cyan
  Write-Host "  エクスプローラーを一旦終了します（タスクバー/デスクトップが数秒消えますが、自動で戻ります）..."
  Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2

  $recent = "$env:APPDATA\Microsoft\Windows\Recent"
  # Recent 直下の *.lnk（最近使ったファイル）と、クイックアクセスのジャンプリスト
  # （AutomaticDestinations／CustomDestinations）の中身を削除する。フォルダ自体は残す。
  foreach ($sub in @('', 'AutomaticDestinations', 'CustomDestinations')) {
    $p = if ($sub) { Join-Path $recent $sub } else { $recent }
    if (Test-Path $p) {
      Get-ChildItem -Path $p -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
  }
  # 検索履歴（WordWheelQuery）・アドレスバー入力履歴（TypedPaths）をレジストリから削除する
  # （エクスプローラー終了中に消すことで、終了時の書き戻しを防ぐ）
  Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery' -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths' -Recurse -Force -ErrorAction SilentlyContinue

  # ※ エクスプローラー（シェル）は明示的には起動し直さない。Windows が自動で復帰させる。
  Write-Host "  最近使ったファイル・クイックアクセス・検索/アドレスバー履歴を削除しました。"
  Write-Host "  ※ タスクバー/デスクトップは Windows が数秒で自動復帰します（戻らない場合はサインアウト/再起動）。"

  # 13. C:\ 直下の非標準フォルダを検知して削除する（研修生が C:\ 直下に作成した可能性。1 件ずつ確認）
  Write-Host ""
  Write-Host "=== C:\ 直下の非標準フォルダを確認します ===" -ForegroundColor Cyan
  $rootDirs = Get-ChildItem -Path 'C:\' -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $StandardRootDirs -notcontains $_.Name }
  if (-not $rootDirs) {
    Write-Host "  C:\ 直下に非標準フォルダはありません。"
  } else {
    Write-Host "  C:\ 直下に標準以外のフォルダが見つかりました（研修生が作成した可能性）:"
    $rootDirs | ForEach-Object { Write-Host "    - C:\$($_.Name)" }
    foreach ($d in $rootDirs) {
      $confirm = Read-Host "「C:\$($d.Name)」を削除しますか？ [y/N]"
      if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $d.FullName) {
          Write-Host "    削除に失敗しました（権限不足の可能性。管理者権限の PowerShell で再実行してください）: C:\$($d.Name)" -ForegroundColor Red
        } else {
          Write-Host "    削除しました: C:\$($d.Name)"
        }
      } else {
        Write-Host "    スキップしました: C:\$($d.Name)"
      }
    }
  }

  # 14. ごみ箱を空にする
  Write-Host ""
  Write-Host "=== ごみ箱を空にします ===" -ForegroundColor Cyan
  Clear-RecycleBin -Force -ErrorAction SilentlyContinue
  Write-Host "  ごみ箱を空にしました。"

  Write-Host ""
  Write-Host "=== Windows側のクリーンアップ完了 ===" -ForegroundColor Green
}

# ===== エントリポイント =====
if ($Check) {
  Invoke-Check
} else {
  Write-Host "これは「クリーンアップ実行」です（削除を行います）。確認だけなら -Check を付けてください。" -ForegroundColor Yellow
  $ans = Read-Host "クリーンアップを実行しますか？ [y/N]"
  if ($ans -ne 'y' -and $ans -ne 'Y') {
    Write-Host "中止しました。確認のみは -Check を付けて実行できます。"
    return
  }
  Invoke-Cleanup

  # 削除に続けて確認（-Check 相当）を自動実行する（read-only）
  Write-Host ""
  Write-Host "続けて確認を行います（-Check と同じ内容）。" -ForegroundColor Cyan
  Write-Host ""
  Invoke-Check
}
