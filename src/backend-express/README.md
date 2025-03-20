# Express API サービス

このサービスは、AWSのFargateで動作するシンプルなExpressアプリケーションです。

## 概要

- ポート3000でHTTPリクエストを受け付けます
- ルートエンドポイント（"/"）へのGETリクエストに対して"Hello World"を返します

## セットアップ

```bash
# 依存関係のインストール
npm install

# 開発サーバーの起動
npm start
```

## Makefileの使い方

このプロジェクトではMakefileを使用して様々な操作を簡略化しています。

### アプリケーション開発

```bash
# 依存関係のインストール（package.jsonの初期化とExpressのインストール）
make setup

# アプリケーションの起動
make start
```

### ファイル生成

```bash
# app.jsファイルの生成
make create-app

# Dockerfileの生成
make create-dockerfile

# 必要なファイルをすべて生成（app.js、Dockerfile、package.json）
make create-all
```

### Docker操作とECRデプロイ

```bash
# ECRレジストリへのログイン
make ecr-login

# Dockerイメージのビルド
make ecr-build

# イメージにタグを付ける
make ecr-tag

# イメージをECRにプッシュ
make ecr-push

# ログイン、ビルド、タグ付け、プッシュの全工程を実行
make ecr-deploy
```

## Docker

```bash
# イメージのビルド
docker build -t ecr-api-3000 .

# コンテナの実行
docker run -p 3000:3000 ecr-api-3000
```

## AWS Fargate

このアプリケーションはAWS Fargateで実行するように設計されています。
