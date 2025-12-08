from typing import List, Optional
from fastapi import FastAPI, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select, col, or_
from app.db import get_session
from app.models import Seed

app = FastAPI(title="FIT Seeds Search API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/search", response_model=List[Seed])
def search_seeds(
    q: str = Query(..., min_length=1, description="Search query"),
    db: Session = Depends(get_session)
):
    """
    Search seeds by keyword across multiple fields:
    - Project Title (JA/EN)
    - Researcher Name
    - Keywords
    - Research Field
    - Description (JA/EN)
    """
    query_str = f"%{q}%"
    statement = select(Seed).where(
        or_(
            col(Seed.project_title).ilike(query_str),
            col(Seed.project_title_en).ilike(query_str),
            col(Seed.researcher_name).ilike(query_str),
            col(Seed.keywords).ilike(query_str),
            col(Seed.research_field).ilike(query_str),
            col(Seed.description).ilike(query_str),
            col(Seed.description_en).ilike(query_str),
        )
    )
    results = db.exec(statement).all()
    return results

@app.get("/health")
def health_check():
    return {"status": "ok"}
