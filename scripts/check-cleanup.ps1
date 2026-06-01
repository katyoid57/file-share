# 研修PCクリーンアップ確認（Windows側）
# 実行例: powershell -ExecutionPolicy Bypass -File .\check-cleanup.ps1

$ErrorActionPreference = 'Continue'

Write-Host "=== クリーンアップ確認（Windows側）==="
Write-Host ""

# ダウンロードフォルダの確認
$downloads = "$env:USERPROFILE\Downloads"
$count = (Get-ChildItem -Path $downloads -Force -ErrorAction SilentlyContinue | Measure-Object).Count
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

Write-Host ""
Write-Host "=== 確認完了 ==="
