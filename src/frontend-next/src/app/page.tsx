import Image from "next/image";

// Express APIからデータを取得する関数
async function getData() {
  // バックエンドのルーティング構成に基づいてエンドポイントを設定
  const isLocalDev = process.env.NODE_ENV === 'development';
  
  // ローカル開発環境: 直接バックエンドのポートにアクセス
  // 本番環境: ALBのパスベースルーティングで /api へのリクエストがバックエンドに転送される
  const apiUrl = isLocalDev ? 'http://localhost:8000/' : '/api';
  
  try {
    const res = await fetch(apiUrl, {
      cache: 'no-store', // SSRで毎回最新データを取得
      headers: {
        'Accept': 'application/json',
      },
    });
    
    if (!res.ok) {
      throw new Error('APIリクエストに失敗しました');
    }
    
    return res.text(); // テキストとして取得（JSONの場合はres.json()を使用）
  } catch (error) {
    console.error('データ取得エラー:', error);
    return 'データ取得に失敗しました';
  }
}

export default async function Home() {
  // APIからデータを取得
  const data = await getData();

  return (
    <div className="grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
      <div className="w-full max-w-4xl">
        <h1 className="text-2xl font-bold mb-4 text-foreground">Express API レスポンス</h1>
        <div className="p-6 border border-[var(--border)] rounded-lg bg-[var(--card-bg)] shadow-lg">
          <pre className="whitespace-pre-wrap break-words">{data}</pre>
        </div>
      </div>
    </div>
  );
}
