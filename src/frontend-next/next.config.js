/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  // FargateでのSSRをサポートするための設定
  experimental: {
    // ホストからの接続を許可
    serverComponentsExternalPackages: ['next']
  },
};

module.exports = nextConfig; 