# Docker Hub設定
DOCKERHUB_REPO := kurosawakuro
DOCKERHUB_IMAGE := frontend-nextjs-3000
DOCKERHUB_TAG := latest

.PHONY: dev build start lint dockerhub-login dockerhub-build dockerhub-push dockerhub-deploy

dev:
	npm run dev

build:
	npm run build

start:
	npm run start

lint:
	npm run lint

# ターボパックで開発サーバーを起動
dev-turbo:
	next dev --turbopack

# デフォルトのコマンド
all: dev

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