# python仮想環境の重複ライブラリ集約スクリプト仕様

## 目的

複数のPython仮想環境で重複するライブラリファイルを、共通ストアにハードリンク集約してディスク使用量を削減する。

対象は主に大容量バイナリを含む`site-packages`配下の通常ファイル。

## 用語

- `venv`: Python仮想環境ディレクトリ（例: `./.venv`）
- `store`: 共通管理ディレクトリ（既定: `$HOME/.cache/unkoenv`）
- `blob`: 実体ファイル（内容ハッシュ名で格納）

## 管理ディレクトリ構造

```text
$HOME/.cache/unkoenv/
  venvs/
   foo -> /abs/path/to/foo/.venv
   bar -> /abs/path/to/bar/.venv
  blobs/
   ab/
    abcd...1234   # sha256(内容) の16進文字列をファイル名に使用
   ff/
    ff98...ee01
  lock/
   unkoenv.lock    # 排他制御用
```

仕様:

- `blobs`のサブディレクトリはハッシュ先頭2文字を使用する（`ab/<fullhash>`）。
- blobファイル名はSHA-256のフルハッシュ（64文字）とする。
- `venvs/<name>`は仮想環境へのシンボリックリンク。

## 対象/非対象

対象:

- `<venv>/lib/python*/site-packages/**` 配下の通常ファイル（`-type f`）

非対象:

- シンボリックリンク
- ディレクトリ
- ソケット/FIFO/デバイスファイル
- `__pycache__`配下（任意、既定で除外推奨）
- `*.pyc`（任意、既定で除外推奨）

## コマンド仕様

### 1. 登録と重複排除

```bash
unkovenv add <venv_dir> [--dry-run] [--verbose]
```

入力:

- `venv_dir`: 仮想環境ディレクトリのパス（相対/絶対どちらも可）
- `venv`名は `basename(venv_dir)` を使用して `venvs/` にシンボリックリンクを作成

処理手順:

1. 事前検証
  - `venv_dir`が存在しディレクトリであること
  - `site-packages`が1つ以上見つかること
2. 排他ロック取得
  - `store/lock/unkoenv.lock`で多重実行を防止
3. `venvs/<alias>`シンボリックリンクを作成または更新
  - 既存で同一リンク先なら何もしない
  - 既存で異なるリンク先ならエラー（`--force-link`導入時のみ上書き可）
4. `site-packages`配下の通常ファイルを走査
  - 各ファイルのSHA-256を計算
  - `blob_path=blobs/${hash:0:2}/$hash`を決定
5. blob作成/再利用
  - blobが存在しない場合: 元ファイルからblobへハードリンク作成
  - blobが存在する場合: 内容同一と見なし再利用
6. 元ファイルをblobへのハードリンクへ置換
  - 一時ファイル経由でアトミックに置換（`mv`）
  - 置換後にinode一致を確認（任意）
7. 集計結果を表示
  - 走査数、集約数、新規blob数、推定削減サイズ、スキップ数

終了コード:

- `0`: 成功
- `1`: 一般エラー（引数不正、権限、I/O）
- `2`: 前提未満足（venv/site-packages未検出）
- `3`: ロック取得失敗
- `4`: 同一ファイルシステム制約違反（EXDEV）

### 2. ガベージコレクション

```bash
unkovenv gc [--dry-run] [--verbose]
```

処理手順:

1. 壊れた`venvs/*`シンボリックリンク削除（リンク先が存在しないもの）
2. `blobs`配下でリンク数1のファイルを削除
3. 空ディレクトリを削除

実装目安コマンド:

- macOS/BSD `find`前提:
  - `find "$store/blobs" -type f -links 1 -delete`
  - `find "$store/blobs" -type d -empty -delete`

### 3. 状態確認（推奨）

```bash
unkovenv status [--json]
```

出力:

- 管理venv数
- blobファイル数
- 推定節約サイズ（可能なら）
- 壊れたリンク件数

## 重要な制約

1. ハードリンクは同一ファイルシステム内のみ

- `venv_dir`と`store/blobs`が別デバイスの場合はハードリンク不可（`EXDEV`）
- この場合はエラー終了（将来`--copy-fallback`を追加してもよい）

2. パーミッション

- 読み取り不可ファイルはスキップし、最後に件数報告
- 書き込み不可ならエラー終了

3. 安全性

- 直接上書きせず、必ず一時ファイルを使って置換
- SIGINT/SIGTERMでロック解放する`trap`を設定

## ハッシュ計算仕様

優先順:

1. `shasum -a 256`
2. `sha256sum`
3. `openssl dgst -sha256`

標準化:

- 出力からハッシュ値（16進64文字）のみ抽出
- 大文字は小文字に正規化

## ログ仕様

- 既定: 要約のみ
- `--verbose`: ファイル単位ログ
- 推奨フォーマット:

```text
[INFO] scan_start venv=/abs/path/.venv
[INFO] linked file=... blob=... hash=...
[WARN] skipped file=... reason=permission_denied
[INFO] gc_removed_orphan count=123
[INFO] done scanned=12000 deduped=9500 new_blobs=600 saved_bytes=123456789
```

## 失敗時リカバリ

- 中断時はロック解除して終了
- 部分的に置換済みでも再実行で収束する（冪等性）
- 壊れたシンボリックリンクは`gc`で修復可能

## 性能要件（初期版）

- 10万ファイル規模で実行可能であること
- メモリ常駐は最小化（1ファイルずつ処理）
- 並列化は初期版では不要（将来`xargs -P`等を検討）

## 実装方針（シェル）

- `bash`または`zsh`で実装（`set -euo pipefail`推奨）
- パスは常にダブルクオート
- 空白/日本語パスに対応
- macOS標準コマンドで動作することを優先

## 受け入れ条件

1. 同一内容ファイルがblobに1つだけ集約される
2. `site-packages`側はblobへのハードリンクになる
3. `gc`で孤立blob（リンク数1）が削除される
4. 壊れた`venvs/*`リンクが削除される
5. 再実行しても結果が壊れない（冪等）
6. `--dry-run`で変更なしで実行内容だけ確認できる

## テスト観点

1. 正常系
  - 同一ファイルが複数venvにある場合
2. 異常系
  - `venv_dir`不存在
  - `site-packages`なし
  - 読み取り/書き込み権限不足
  - 別ファイルシステム（EXDEV）
3. 運用系
  - 実行中断後の再実行
  - 壊れたリンク混在での`gc`

## 将来拡張

- `unkovenv verify`: blobとリンク整合性検査
- `unkovenv doctor`: 問題検出と修復提案
- `--exclude`/`--include`パターン指定
- JSONログ/メトリクス出力

