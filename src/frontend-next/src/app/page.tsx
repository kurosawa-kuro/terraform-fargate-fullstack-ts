'use client';

import { useEffect, useState } from "react";

export default function Home() {
  const [data, setData] = useState<string>('読み込み中...');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Next.jsのrewrites設定で/api/*は適切なバックエンドURLにリダイレクトされる
        const res = await fetch('/api', {
          cache: 'no-store',
        });
        
        if (!res.ok) {
          throw new Error(`APIリクエスト失敗: ${res.status}`);
        }
        
        const result = await res.text();
        setData(result);
      } catch (error) {
        console.error('データ取得エラー:', error);
        setError(`データ取得に失敗しました: ${error instanceof Error ? error.message : String(error)}`);
      }
    };

    fetchData();
  }, []);

  return (
    <div className="grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
      <div className="w-full max-w-4xl">
        <h1 className="text-2xl font-bold mb-4 text-foreground">Express API レスポンス</h1>
        {error && (
          <div className="p-4 mb-4 bg-red-100 border border-red-400 text-red-700 rounded">
            {error}
          </div>
        )}
        <div className="p-6 border border-[var(--border)] rounded-lg bg-[var(--card-bg)] shadow-lg">
          <pre className="whitespace-pre-wrap break-words">{data}</pre>
        </div>
      </div>
    </div>
  );
}
