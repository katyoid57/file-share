# 研修PCクリーンアップ（Windows側）
# 実行: powershell -ExecutionPolicy Bypass -File .\cleanup.ps1          … クリーンアップ（削除）を行う
# 確認: powershell -ExecutionPolicy Bypass -File .\cleanup.ps1 -Check   … 確認のみ（read-only。何度でも安全に実行可）
#   ブラウザ(Chrome/Edge)のCookie・履歴・ブックマーク・タブ削除、メモ帳の未保存タブ削除、Zoom のログイン情報削除、
#   ダウンロードフォルダの全削除、ピクチャのスクリーンショット削除、ごみ箱を空にする。
param([switch]$Check)

$ErrorActionPreference = 'Continue'

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

  # デスクトップ / ドキュメントのファイル・フォルダ一覧（参考表示のみ。判定はしない。
  # ショートカットに限らず全項目を表示する。セットアップ手順以外があれば手動で削除する）
  # -Force を付けないので隠しファイル・システムファイル（desktop.ini 等）は除外される
  $listDirs = @(
    @{ Name = 'デスクトップ';   Path = [Environment]::GetFolderPath('Desktop') },
    @{ Name = 'ドキュメント';   Path = [Environment]::GetFolderPath('MyDocuments') }
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
  # 1. ブラウザ・メモ帳・Zoom を終了する（プロファイル/未保存タブ/ログイン情報のロックを外すため。-Force で未保存内容ごと閉じる）
  Write-Host "=== ブラウザ・メモ帳・Zoom を終了します ===" -ForegroundColor Cyan
  foreach ($name in @('chrome', 'msedge', 'notepad', 'Zoom')) {
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

  # 5. ダウンロードフォルダの中身を全削除する
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

  # 6. ピクチャのスクリーンショットを削除する（Snipping Tool の自動保存・Win+PrtScn の保存先）
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

  # 7. ごみ箱を空にする
  Write-Host ""
  Write-Host "=== ごみ箱を空にします ===" -ForegroundColor Cyan
  Clear-RecycleBin -Force -ErrorAction SilentlyContinue
  Write-Host "  ごみ箱を空にしました。"

  Write-Host ""
  Write-Host "=== Windows側のクリーンアップ完了 ===" -ForegroundColor Green
  Write-Host "  ※ -Check を付けて再実行すると、クリーンアップ済みか確認できます。"
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
}
