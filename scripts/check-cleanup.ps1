# 研修PCクリーンアップ確認（Windows側）
# 実行例: powershell -ExecutionPolicy Bypass -File .\check-cleanup.ps1

$ErrorActionPreference = 'Continue'

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

# デスクトップ / ドキュメントの余分なショートカット確認（セットアップで作られる VSCode 以外）
$expected = @('Visual Studio Code')   # セットアップで作られる想定のショートカット名（拡張子を除いた名前）
$shortcutDirs = @(
  @{ Name = 'デスクトップ';   Path = [Environment]::GetFolderPath('Desktop') },
  @{ Name = 'ドキュメント';   Path = [Environment]::GetFolderPath('MyDocuments') }
)
foreach ($d in $shortcutDirs) {
  $stray = Get-ChildItem -Path $d.Path -Filter *.lnk -Force -ErrorAction SilentlyContinue |
           Where-Object { $expected -notcontains $_.BaseName }
  if ($stray) {
    Write-Host "[NG] $($d.Name): セットアップ手順以外のショートカットがあります（要確認・手動削除）:" -ForegroundColor Red
    $stray | ForEach-Object { Write-Host "       - $($_.Name)" }
  } else {
    Write-Host "[OK] $($d.Name): セットアップ以外のショートカットなし" -ForegroundColor Green
  }
}

Write-Host ""
Write-Host "=== 確認完了 ==="
