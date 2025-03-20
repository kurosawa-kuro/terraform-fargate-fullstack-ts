
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
    
    return res.json(); // JSONとして取得
  } catch (error) {
    console.error('データ取得エラー:', error);
    return {
      message: 'データ取得に失敗しました',
      error: error instanceof Error ? error.message : String(error)
    };
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
          <div className="mb-4">
            <h2 className="text-xl font-semibold">メッセージ</h2>
            <p className="text-lg">{data.message}</p>
          </div>
          {data.serverTime && (
            <div className="mb-4">
              <h2 className="text-xl font-semibold">サーバー時間</h2>
              <p className="text-lg">{data.serverTime}</p>
            </div>
          )}
          {data.environment && (
            <div className="mb-4">
              <h2 className="text-xl font-semibold">環境</h2>
              <p className="text-lg">{data.environment}</p>
            </div>
          )}
          <div className="mt-6">
            <h2 className="text-xl font-semibold">JSON データ</h2>
            <pre className="bg-gray-100 dark:bg-gray-800 p-4 rounded overflow-auto mt-2">
              {JSON.stringify(data, null, 2)}
            </pre>
          </div>
        </div>
      </div>
    </div>
  );
}
