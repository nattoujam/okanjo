# okanjo

![version](https://img.shields.io/github/v/tag/nattoujam/okanjo?label=version&color=blue&sort=semver)
![Ruby](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2Fnattoujam%2Fokanjo%2Frefs%2Fheads%2Fmaster%2F.tool-versions&search=%5Eruby%20%28.*%29%24&replace=%241&flags=m&label=Ruby&color=CC342D&logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2Fnattoujam%2Fokanjo%2Frefs%2Fheads%2Fmaster%2FGemfile.lock&search=%5E%20%20%20%20rails%20%5C%28%28.*%29%5C%29&replace=%241&flags=m&label=Rails&color=D30001&logo=rubyonrails&logoColor=white)

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
