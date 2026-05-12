# 開発環境クリーンアップ手順

## 概要

研修終了後、PCを次回研修用に戻すための手順です。  
以下のクリーンアップを実施します。

- Claude Code 認証解除
- GitHub CLI 認証解除
- 研修資料フォルダの削除

---

## クリーンアップ手順

VSCode のメニューバー → **ターミナル** → **新しいターミナル**（または `Ctrl+@`）で VSCode 内のターミナルを開き、以下を実行する。

```bash
bash ~/scripts/cleanup.sh
```

実行後、削除する研修フォルダ名の入力を求められるので入力する。

---

## 手動で実施する場合

### 1. Claude Code 認証解除

```bash
claude logout
```

### 2. GitHub CLI 認証解除

```bash
gh auth logout
```

### 3. 研修資料フォルダの削除

```bash
rm -rf ~/（研修フォルダ名）
```

---

## シェルスクリプトで一括クリーンアップする場合

WSL ターミナルで以下を実行する。

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/cleanup.sh -o cleanup.sh
```

```bash
# 実行
bash cleanup.sh
```

```bash
# 後片付け
rm cleanup.sh
```

実行後、削除する研修フォルダ名の入力を求められるので入力する。

### check-cleanup.sh でクリーンアップ確認

```bash
# ダウンロード
curl -fsSL https://raw.githubusercontent.com/katyoid57/file-share/main/scripts/check-cleanup.sh -o check-cleanup.sh
```

```bash
# 実行
bash check-cleanup.sh
```

```bash
# 後片付け
rm check-cleanup.sh
```

> 各項目に `[OK]` が表示されていればクリーンアップ完了。`[NG]` の場合は該当ステップを見直すこと。
