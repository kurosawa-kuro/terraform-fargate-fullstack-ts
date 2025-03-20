# ------------ ビルドステージ ------------
FROM node:20-alpine AS build

WORKDIR /app

# 依存関係 (package*.json) と tsconfig.json を先にコピー
# これらのみをコピーすることで、ライブラリインストールのレイヤーをキャッシュ化
COPY package.json package-lock.json tsconfig.json ./

# 依存関係インストール
RUN npm ci

# 残りのソースコードをコピー
COPY . .

# Next.js のビルド（tsconfig.json があると自動的にTypeScript対応ビルド）
RUN npm run build


# ------------ 実行ステージ ------------
FROM node:20-alpine AS runner

WORKDIR /app

# 本番用の環境変数
ENV NODE_ENV=production

# 必要なファイルをビルドステージからコピー
COPY --from=build /app/package.json ./
COPY --from=build /app/package-lock.json ./
COPY --from=build /app/next.config.* ./
COPY --from=build /app/public ./public
COPY --from=build /app/.next ./.next

# 本番環境用依存関係のみインストール (devDependencies除外)
RUN npm ci --omit=dev

# ポート 3000 を公開
EXPOSE 3000

# アプリケーションを起動
CMD ["npm", "start"]
