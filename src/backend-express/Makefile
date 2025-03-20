# ECR API 3000 - Makefile

###########################################
# 環境変数の設定
###########################################
# AWS ECR関連
ECR_REPO = 503561449641.dkr.ecr.ap-northeast-1.amazonaws.com/ecr-api-3000
AWS_REGION = ap-northeast-1
IMAGE_NAME = ecr-api-3000
IMAGE_TAG = latest

# アプリケーション設定
APP_PORT = 3000

# DockerHub設定
DOCKERHUB_REPO = kurosawakuro
DOCKERHUB_IMAGE = backend-express-8000
DOCKERHUB_TAG = latest

###########################################
# デフォルト設定
###########################################
.DEFAULT_GOAL := help

.PHONY: help setup start dev \
        ecr-login ecr-build ecr-tag docker-stop ecr-push ecr-deploy \
        dockerhub-login dockerhub-build dockerhub-push dockerhub-deploy

###########################################
# ヘルプコマンド
###########################################
help:
	@echo "使用可能なコマンド:"
	@echo "--------------------------------"
	@echo "Node.jsアプリケーション:"
	@echo "  make setup           - package.jsonの初期化とExpressのインストール"
	@echo "  make start           - アプリケーションの起動"
	@echo "  make dev             - nodemonを使用した開発モードでの起動"
	@echo "--------------------------------"
	@echo "Docker - AWS ECR:"
	@echo "  make ecr-login       - ECRレジストリへのログイン"
	@echo "  make ecr-build       - Dockerイメージのビルド"
	@echo "  make ecr-tag         - イメージにタグを付ける"
	@echo "  make docker-stop     - 実行中のコンテナを停止"
	@echo "  make ecr-push        - イメージをECRにプッシュ"
	@echo "  make ecr-deploy      - ログイン、ビルド、タグ付け、プッシュの全工程を実行"
	@echo "--------------------------------"
	@echo "Docker - DockerHub:"
	@echo "  make dockerhub-login - DockerHubへのログイン"
	@echo "  make dockerhub-build - Dockerイメージのビルド"
	@echo "  make dockerhub-push  - イメージをDockerHubにプッシュ"
	@echo "  make dockerhub-deploy - ログイン、ビルド、プッシュの全工程を実行"

###########################################
# Node.js関連コマンド
###########################################
setup:
	npm init -y
	npm install express
	npm install --save-dev nodemon

start:
	npm run start

dev:
	npm run dev

###########################################
# AWS ECR関連コマンド
###########################################
ecr-login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REPO)

ecr-build:
	docker build -t $(IMAGE_NAME) .

ecr-tag:
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(ECR_REPO):$(IMAGE_TAG)

docker-stop:
	docker stop $$(docker ps -q --filter ancestor=$(IMAGE_NAME):$(IMAGE_TAG)) 2>/dev/null || echo "実行中のコンテナがありません"

ecr-push:
	docker push $(ECR_REPO):$(IMAGE_TAG)

ecr-deploy: ecr-login ecr-build ecr-tag ecr-push
	@echo "ECRへのデプロイが完了しました"

###########################################
# DockerHub関連コマンド
###########################################
dockerhub-login:
	docker login

dockerhub-build:
	docker build -t $(DOCKERHUB_REPO)/$(DOCKERHUB_IMAGE):$(DOCKERHUB_TAG) .

dockerhub-push:
	docker push $(DOCKERHUB_REPO)/$(DOCKERHUB_IMAGE):$(DOCKERHUB_TAG)

dockerhub-deploy: dockerhub-login dockerhub-build dockerhub-push
	@echo "DockerHubへのデプロイが完了しました"