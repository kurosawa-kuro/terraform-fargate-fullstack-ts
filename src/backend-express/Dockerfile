FROM node:18-alpine

WORKDIR /app

# package.jsonとpackage-lock.jsonをコピー
COPY package*.json ./

# 依存関係のインストール（dotenvを含む）
RUN npm ci --only=production

# アプリケーションのソースコードをコピー
COPY app.js ./

# 非rootユーザーでアプリケーションを実行
USER node

# アプリケーションが使用するポートを公開
EXPOSE 8000

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8000/ || exit 1

# コンテナ起動時に実行するコマンド
CMD ["node", "app.js"]
