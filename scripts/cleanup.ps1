# 研修PCクリーンアップ（Windows側）
# Chrome / Edge の Cookie・閲覧履歴・ブックマーク削除、ダウンロードフォルダの全削除、ごみ箱を空にする。
# 実行例: powershell -ExecutionPolicy Bypass -File .\cleanup.ps1

$ErrorActionPreference = 'Continue'

# 1. ブラウザを終了する（プロファイルのロックを外すため）
Write-Host "=== ブラウザを終了します ===" -ForegroundColor Cyan
foreach ($name in @('chrome', 'msedge')) {
  Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# 2. Cookie・閲覧履歴・ブックマークを削除する
Write-Host ""
Write-Host "=== ブラウザの Cookie・閲覧履歴・ブックマークを削除します ===" -ForegroundColor Cyan
$browsers = @(
  @{ Name = 'Chrome'; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default" },
  @{ Name = 'Edge';   Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" }
)
$targets = @('Network\Cookies', 'Cookies', 'History', 'Bookmarks', 'Bookmarks.bak')
foreach ($b in $browsers) {
  if (Test-Path $b.Path) {
    foreach ($t in $targets) {
      $f = Join-Path $b.Path $t
      if (Test-Path $f) { Remove-Item $f -Force -ErrorAction SilentlyContinue }
    }
    Write-Host "  クリア: $($b.Name)"
  } else {
    Write-Host "  スキップ: $($b.Name) はインストールされていません"
  }
}
Write-Host "  ※ サーバー側セッション無効化のため、事前に claude.ai / GitHub を手動ログアウトしておくと確実です。"

# 3. ダウンロードフォルダの中身を全削除する
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

# 4. ごみ箱を空にする
Write-Host ""
Write-Host "=== ごみ箱を空にします ===" -ForegroundColor Cyan
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "  ごみ箱を空にしました。"

Write-Host ""
Write-Host "=== Windows側のクリーンアップ完了 ===" -ForegroundColor Green
