# ビルドステージ
# Node.js 20 Alpineイメージを使用（軽量）
FROM node:20-alpine AS build

WORKDIR /app

# 依存関係をコピーしてインストール
# package.jsonとpackage-lock.jsonのみをコピーしてレイヤーキャッシュを最適化
COPY package.json package-lock.json tsconfig.json ./
RUN npm ci

# ソースコードをコピー
COPY . .

# アプリケーションをビルド
RUN npm run build

# 実行ステージ
# マルチステージビルドで最小限のイメージサイズを実現
FROM node:20-alpine AS runner

WORKDIR /app

# 本番環境用の環境変数を設定
ENV NODE_ENV=production
# バックエンドAPIのURLを設定（ECSのサービスディスカバリー使用）
ENV API_URL=http://fullstack-public-01-backend-service:8000

# 必要なファイルだけをコピー
# ビルドステージから最小限のファイルセットのみをコピー
COPY --from=build /app/package.json ./
COPY --from=build /app/package-lock.json ./
COPY --from=build /app/next.config.ts ./
COPY --from=build /app/public ./public
COPY --from=build /app/.next ./.next

# 本番環境用の依存関係のみをインストール
RUN npm ci --omit=dev

# ポート3000を公開
EXPOSE 3000

# アプリケーションを実行
CMD ["npm", "start"]
