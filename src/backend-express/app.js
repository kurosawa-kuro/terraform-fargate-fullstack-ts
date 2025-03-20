/**
 * アプリケーションエントリーポイント
 * 
 * このファイルは、Expressアプリケーションのメインエントリーポイントとなるもので、
 * 環境変数の設定、ルーティング、ミドルウェア、サービス、およびサーバー起動を管理します。
 */

// -----------------------------------------------------------------------------
// モジュールのインポート
// -----------------------------------------------------------------------------
const express = require("express");
const { Client } = require("pg");
const cors = require("cors");

// -----------------------------------------------------------------------------
// サービス層の定義
// -----------------------------------------------------------------------------
/**
 * アプリケーションサービス
 */
const appService = {
  /**
   * メインページのデータを取得する
   * @returns {Object} メインページに表示するデータ
   */
  getMainPageData: () => {
    return { message: "Hello World" };
  },

  /**
   * 環境変数情報を取得する
   * @returns {Object} 環境変数情報
   */
  getEnvironmentInfo: () => {
    return {
      application: {
        backendPort: process.env.BACKEND_PORT,
        frontendPort: process.env.FRONTEND_PORT
      },
      database: {
        url: process.env.DATABASE_URL
      },
      auth: {
        jwtSecretKey: process.env.JWT_SECRET_KEY,
        nodeEnv: process.env.NODE_ENV
      },
      upload: {
        uploadDir: process.env.UPLOAD_DIR
      }
    };
  },

  /**
   * PostgreSQLデータベース接続をテストする
   * @returns {Promise<Object>} 接続結果
   */
  testDatabaseConnection: async () => {
    const dbUrl = process.env.DATABASE_URL;
    
    if (!dbUrl) {
      return { success: false, message: "DATABASE_URL環境変数が設定されていません" };
    }

    const client = new Client({
      connectionString: dbUrl,
      ssl: {
        rejectUnauthorized: false // 開発環境ではSSL検証をスキップ
      }
    });

    try {
      await client.connect();
      const result = await client.query('SELECT NOW() as current_time');
      await client.end();
      
      return {
        success: true,
        message: "データベース接続に成功しました",
        timestamp: result.rows[0].current_time
      };
    } catch (error) {
      return {
        success: false,
        message: `データベース接続に失敗しました: ${error.message}`,
        error: error.stack
      };
    }
  }
};

// -----------------------------------------------------------------------------
// 環境変数の設定
// -----------------------------------------------------------------------------
/**
 * 環境変数を初期化する
 */
function setupEnvironmentVariables() {
  if (process.env.NODE_ENV !== 'production') {
    try {
      require('dotenv').config();
      console.log('.envファイルから環境変数を読み込みました');
    } catch (error) {
      console.log('dotenvモジュールがインストールされていないか、.envファイルがありません。環境変数を直接使用します。');
    }
  } else {
    console.log('本番環境のため、AWS SSMパラメータストアから環境変数を使用します');
  }
}

// -----------------------------------------------------------------------------
// ミドルウェアの設定
// -----------------------------------------------------------------------------
/**
 * アプリケーションミドルウェアを設定する
 * @param {Object} app - Expressアプリケーションインスタンス
 */
function setupMiddleware(app) {
  // CORS設定
  const corsOptions = {
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
  };
  
  app.use(cors(corsOptions));
  
  // JSON本文の解析
  app.use(express.json());
  
  // URLエンコードされたデータの解析
  app.use(express.urlencoded({ extended: true }));
}

// -----------------------------------------------------------------------------
// コントローラー層の定義
// -----------------------------------------------------------------------------
/**
 * アプリケーションコントローラー
 */
const appController = {
  /**
   * メインページを表示する
   * @param {Object} req - リクエストオブジェクト
   * @param {Object} res - レスポンスオブジェクト
   */
  showMainPage: (req, res) => {
    console.log("APIリクエストを受信しました");
    const data = appService.getMainPageData();
    res.json({
      message: data.message,
      serverTime: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development'
    });
  }
};

// -----------------------------------------------------------------------------
// ルーティングの設定
// -----------------------------------------------------------------------------
/**
 * ルーティングを設定する
 * @param {Object} app - Expressアプリケーションインスタンス
 */
function setupRoutes(app) {
  // ルートパスでメインページを表示
  app.get("/", appController.showMainPage);
  
  // ALBのパスベースルーティング用に /api エンドポイントを追加
  app.get("/api", appController.showMainPage);
}

// -----------------------------------------------------------------------------
// サーバー起動とロギングの設定
// -----------------------------------------------------------------------------
/**
 * 環境変数の情報をログに出力する
 */
async function logEnvironmentInfo() {
  const envInfo = appService.getEnvironmentInfo();

  console.log("Github Action動作確認 ３３:");
  
  console.log("環境変数:");
  console.log("====================");
  console.log(`アプリケーションポート:`);
  console.log(`- BACKEND_PORT: ${envInfo.application.backendPort}`);
  console.log(`- FRONTEND_PORT: ${envInfo.application.frontendPort}`);
  console.log(`\nデータベース接続情報:`);
  console.log(`- DATABASE_URL: ${envInfo.database.url}`);
  console.log(`\n認証情報:`);
  console.log(`- JWT_SECRET_KEY: ${envInfo.auth.jwtSecretKey}`);
  console.log(`- NODE_ENV: ${envInfo.auth.nodeEnv}`);
  console.log(`\nアップロード設定:`);
  console.log(`- UPLOAD_DIR: ${envInfo.upload.uploadDir}`);
  console.log("====================");

  // PostgreSQL接続テスト
  console.log("\nPostgreSQL接続テスト:");
  console.log("====================");
  try {
    const dbTestResult = await appService.testDatabaseConnection();
    if (dbTestResult.success) {
      console.log(`✅ ${dbTestResult.message}`);
      console.log(`📅 サーバー時間: ${dbTestResult.timestamp}`);
    } else {
      console.log(`❌ ${dbTestResult.message}`);
      if (dbTestResult.error) {
        console.log(`エラー詳細: ${dbTestResult.error}`);
      }
    }
  } catch (error) {
    console.log(`❌ 予期せぬエラーが発生しました: ${error.message}`);
  }
  console.log("====================");
}

/**
 * サーバーを起動する
 * @param {Object} app - Expressアプリケーションインスタンス
 */
async function startServer(app) {
  const port = 8000;
  
  app.listen(port, async () => {
    await logEnvironmentInfo();
    console.log(`サーバーはポート ${port} で起動しています`);
  });
}

// -----------------------------------------------------------------------------
// アプリケーションの初期化と起動
// -----------------------------------------------------------------------------
/**
 * アプリケーションを初期化し起動する
 */
function initializeApp() {
  // 環境変数のセットアップ
  setupEnvironmentVariables();
  
  // Expressアプリケーションの作成
  const app = express();
  
  // ミドルウェアの設定
  setupMiddleware(app);
  
  // ルーティングの設定
  setupRoutes(app);
  
  // サーバーの起動
  startServer(app);
}

// アプリケーションを実行
initializeApp();
