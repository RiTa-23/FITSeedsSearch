from sqlmodel import SQLModel, create_engine, Session

# PostgreSQL connection string
import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://rita@localhost:5432/fitseeds"
)

if not DATABASE_URL:
    raise ValueError("DATABASE_URL環境変数が設定されていません。")

engine = create_engine(DATABASE_URL)

def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
