# ビルドステージ
FROM node:20-alpine AS build

WORKDIR /app

# 依存関係をコピーしてインストール
COPY package.json package-lock.json ./
RUN npm ci

# ソースコードをコピー
COPY . .

# next.config.tsをnext.config.jsにリネーム
# RUN if [ -f next.config.ts ]; then mv next.config.ts next.config.js; fi

# アプリケーションをビルド
RUN npm run build

# 実行ステージ
FROM node:20-alpine AS runner

WORKDIR /app

# 本番環境用の環境変数を設定
ENV NODE_ENV=production

# non-root ユーザーを作成
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# 必要なファイルだけをコピー
COPY --from=build /app/public ./public
COPY --from=build --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /app/.next/static ./.next/static

# ユーザーを変更
USER nextjs

# ポート3000を公開
EXPOSE 3000

# 環境変数を設定
ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

# サーバーを起動
CMD ["node", "server.js"] 