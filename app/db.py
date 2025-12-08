from sqlmodel import SQLModel, create_engine, Session

# PostgreSQL connection string
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./fitseeds.db")

# Railway fix:
# 1. "postgres://" -> "postgresql://" (Old Railway format)
# 2. "postgresql://" -> "postgresql+psycopg://" (Force psycopg 3 driver since we don't have psycopg2)
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+psycopg://", 1)
elif DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg://", 1)

if not DATABASE_URL:
    raise ValueError("DATABASE_URL環境変数が設定されていません。")

engine = create_engine(DATABASE_URL)

def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
