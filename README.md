# warikan

## 動作環境

- Ruby 4.0.2
- SQLite3

## セットアップ & 起動

### 初回 / 環境リセット時

依存パッケージのインストール、DBの準備、サーバー起動をまとめて行います。

```sh
bin/setup
```

DBをリセットしたい場合:

```sh
bin/setup --reset
```

### 2回目以降

```sh
bin/dev
```

Rails サーバーと Tailwind CSS の watch が同時に起動します。

ブラウザで http://localhost:3000 を開いてください。
