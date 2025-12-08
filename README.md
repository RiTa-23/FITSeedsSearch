# FITSeedsSearch

福岡工業大学の研究シーズデータを対象に、フリー検索を提供するPythonWebアプリです。

## アプリケーション概要
`fit_seeds_cleaned.csv` に含まれる研究課題データ（タイトル、キーワード、研究内容など）を対象に、フリーワードで横断検索を行います。

### 主な機能
- **キーワード検索**: 日本語・英語のプロジェクト名、研究者名、概要などを対象に検索。
- **結果表示**: 検索結果を一覧表示し、詳細を確認可能。

## 使用技術
- **Backend**: FastAPI
- **Frontend**: Streamlit
- **Database**: PostgreSQL
- **Manager**: uv

## ディレクトリ構成
```text
.
├── app/
│   ├── main.py        # バックエンドAPI (FastAPI)
│   ├── db.py          # データベース接続
│   └── models.py      # データモデル定義
├── frontend/
│   └── app.py         # フロントエンド (Streamlit)
├── scripts/
│   └── ingest_data.py # データインポート用スクリプト
└── fit_seeds_cleaned.csv
```

## セットアップ

### 1. 前提条件
以下のツールがインストールされていること。
- Python 3.12+ (uv推奨)
- **uv** (Pythonパッケージマネージャー)
- **PostgreSQL**

### 2. データベースの準備
PostgreSQLサーバーを起動し、データベースを作成します。
```bash
brew services start postgresql@14  # Mac (Homebrew) の場合
createdb fitseeds
```

### 3. プロジェクトのインストール
`uv` を使用して依存関係をインストールします。
```bash
uv sync
```

### 4. データのインポート
初期データをデータベースに投入します。
```bash
PYTHONPATH=. uv run python scripts/ingest_data.py
```

## 使い方

### 1. サーバーの起動
バックエンド（API）とフロントエンドを別々のターミナルで起動します。

**Term 1: バックエンド**
```bash
uv run uvicorn app.main:app --reload
```
- API Docs: http://localhost:8000/docs

**Term 2: フロントエンド**
```bash
uv run streamlit run frontend/app.py
```
- Web UI: http://localhost:8501

### 2. 検索の実行
ブラウザで http://localhost:8501 にアクセスし、検索ボックスにキーワード（例: "AI", "ロボット", "5G"）を入力して検索してください。
