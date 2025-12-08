from sqlmodel import SQLModel, create_engine, Session

# PostgreSQL connection string
# Using default Homebrew postgres setup: user='rita', no password, db='fitseeds', host='localhost'
DATABASE_URL = "postgresql+psycopg://rita@localhost:5432/fitseeds"

engine = create_engine(DATABASE_URL)

def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
