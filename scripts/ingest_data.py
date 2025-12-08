import pandas as pd
from sqlmodel import Session, select
from app.db import engine, init_db
from app.models import Seed

def ingest():
    print("Initializing database...")
    init_db()
    
    csv_path = "fit_seeds_cleaned.csv"
    print(f"Reading {csv_path}...")
    
    # Read CSV, handle NaN as None
    df = pd.read_csv(csv_path)
    df = df.where(pd.notnull(df), None)
    
    print(f"Found {len(df)} records. Inserting into database...")
    
    with Session(engine) as session:
        # Check if empty to avoid duplicates on re-run (simple check)
        existing = session.exec(select(Seed)).first()
        if existing:
            print("Database already contains data. Skipping ingestion.")
            return

        for _, row in df.iterrows():
            seed = Seed(
                proposal_id=row["研究課題/領域番号"],
                project_title=row["研究課題名"],
                project_title_en=row["研究課題名 (英文)"],
                researcher_name=row["教員名"],
                representative=row["研究代表者"],
                keywords=row["キーワード"],
                research_field=row["研究分野"],
                description=row["研究内容"],
                description_en=row["研究内容 (英文)"]
            )
            session.add(seed)
        
        session.commit()
    print("Ingestion complete.")

if __name__ == "__main__":
    ingest()
