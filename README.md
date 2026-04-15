# okanjo

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

## デプロイ

[Kamal](https://kamal-deploy.org/) を使ってデプロイします。

### 事前準備

#### direnvのセットアップ

環境変数の管理に [direnv](https://direnv.net/) を使用します。

```sh
sudo apt install direnv
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc  # bash の場合は hook bash
source ~/.zshrc
direnv allow  # プロジェクトディレクトリで実行
```

#### シークレット・設定ファイルの作成

`.kamal/secrets` にシークレットを設定する

```
RAILS_MASTER_KEY=<config/master.keyの内容>
KAMAL_REGISTRY_PASSWORD=<Docker Hubのアクセストークン>
```

`.env.deploy` にdeploy設定を記述する

```
DOCKER_USERNAME=<Docker Hubのユーザー名>
DOCKER_IMAGE=<Docker Hubのイメージ名>
PROXY_HOST=<公開ホスト名 (例: example.com)>
DEPLOY_SERVER=<デプロイ先サーバーのIPアドレス>
SSH_PROXY=<SSHプロキシ (user@host形式)>
SSH_USER=<SSHユーザー名>
SSH_KEY_PATH=<SSH秘密鍵のパス>
```

### 初回デプロイ

サーバーへのDockerインストールとアプリのセットアップをまとめて行います。

```sh
bin/kamal setup
```

### 2回目以降

```sh
bin/kamal deploy
```

### 便利なエイリアス

```sh
bin/kamal console  # Rails コンソール
bin/kamal shell    # サーバー上でbash
bin/kamal logs     # ログをtail
bin/kamal dbc      # Rails dbconsole
```
