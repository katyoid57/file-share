# scripts

研修用 PC のセットアップとクリーンアップに使うスクリプト。**どの研修のどの工程で使うか**を取り違えないよう、上流工程研修用のものには `-upstream` を付けている。

| ファイル | 対象の研修 | 実行する場所 | 用途 | 手順書 |
|---|---|---|---|---|
| `setup.sh` | 下流工程研修・AI駆動開発研修 | WSL（Ubuntu） | CLI・JDK・Maven の導入 | [00_DevEnvironmentSetup.md](../00_DevEnvironmentSetup.md) |
| `setup-upstream.ps1` | **上流工程研修** | Windows PowerShell | Git・Python・Node.js・LibreOffice・Claude デスクトップアプリの導入 | [04_UpstreamSetup.md](../04_UpstreamSetup.md) |
| `cleanup.sh` | 下流工程研修・AI駆動開発研修 | WSL（Ubuntu） | WSL 側の認証・履歴・研修資料の削除 | [03_DevEnvironmentCleanup.md](../03_DevEnvironmentCleanup.md) |
| `cleanup.ps1` | **全研修で共通** | Windows PowerShell | ブラウザ・Zoom・Teams・Outlook・Office・資格情報・ダウンロード・ごみ箱の削除 | [03](../03_DevEnvironmentCleanup.md)（下流）／[06](../06_UpstreamCleanup.md)（上流） |
| `cleanup-upstream.ps1` | **上流工程研修** | Windows PowerShell | Claude デスクトップアプリ・Claude Code・配布フォルダ・Git Bash・LibreOffice・キャッシュ・ファイル履歴の削除 | [06_UpstreamCleanup.md](../06_UpstreamCleanup.md) |
| `uninstall-upstream.ps1` | **上流工程研修（検証用）** | Windows PowerShell | `setup-upstream.ps1` で入れたものを全部削除し、最初からやり直せる状態に戻す | [04_UpstreamSetup.md](../04_UpstreamSetup.md) の付録 |
| `diag-accounts.ps1` | 調査用 | Windows PowerShell | アカウントの残存を調べる | — |

## 共通の作法

- `.ps1` はいずれも **`-Check` を付けると確認のみ**（read-only）で実行できる。何度実行しても安全。
- 削除や導入を行うモードは、実行前に `y/N` の確認が入る。
- 完了後は続けて確認（`-Check` 相当）が自動で実行される。
- 日本語のメッセージを含むため、`.ps1` は **UTF-8 BOM 付き**で保存する（Windows PowerShell 5.1 で文字化けさせないため）。
- 動作環境は **Windows PowerShell 5.1**。PowerShell 7 の構文は使わない。

## クリーンアップの順番

上流工程研修の PC は、**`cleanup-upstream.ps1` → `cleanup.ps1`** の順で実行する。`cleanup.ps1` が最後にごみ箱を空にするため、逆順だと手作業で削除したファイルがごみ箱に残る。
