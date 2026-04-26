[English README](./README.md)

# unkovenv

複数の Python 仮想環境で重複する `site-packages` 配下のファイルを、共通ストアへのハードリンクに集約してディスク使用量を削減するツールです。

## 概要

`unkovenv` は `lib/python*/site-packages` 配下の通常ファイルを走査し、各ファイルの SHA-256 を計算して内容ベースで `blobs` に保存します。重複ファイルは同じ blob へのハードリンクに置き換えます。

既定のストアパス:

- `$HOME/.cache/unkoenv`

## 主な機能

- `add`: 仮想環境を登録して重複排除
- `gc`: 孤立 blob と壊れた venv リンクを削除
- `status`: 管理 venv 数、blob 数、推定節約サイズを表示
- `--dry-run`: 変更せずに実行内容を確認
- `--verbose`: ファイル単位ログ

## 動作要件

- macOS (BSD 系コマンド前提)
- Bash または Zsh
- 次のいずれかのハッシュコマンド:
  - `shasum -a 256`
  - `sha256sum`
  - `openssl dgst -sha256`

## 使い方

```bash
# 1つの仮想環境を重複排除
./unkovenv add /path/to/.venv

# ドライラン + 詳細ログ
./unkovenv add /path/to/.venv --dry-run --verbose

# ガベージコレクション
./unkovenv gc

# 状態表示
./unkovenv status
./unkovenv status --json
```

環境変数:

- `UNKOENV_STORE`: ストアパス上書き (最優先)
- `UNKOENV_STORE_DIR`: ストアパス上書き (フォールバック)

## 終了コード

- `0`: 成功
- `1`: 一般エラー (引数不正、権限、I/O など)
- `2`: 前提未満足 (`venv` または `site-packages` 未検出)
- `3`: ロック取得失敗
- `4`: 別ファイルシステムでのハードリンク失敗 (`EXDEV`)

## 注意事項

- ハードリンクは同一ファイルシステム内でのみ有効です。
- `__pycache__` と `*.pyc` は重複排除対象外です。
- 再実行しても収束するように設計されています (冪等性)。

## テスト

```bash
./tests/test_unkoenv.sh
```

## ライセンス

MIT ライセンス。詳細は [LICENSE](./LICENSE) を参照してください。
