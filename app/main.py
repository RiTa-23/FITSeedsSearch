from typing import List, Optional
from fastapi import FastAPI, Depends, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select, col, or_
from app.db import get_session
from app.models import Seed

import os

app = FastAPI(title="FIT Seeds Search API")

# CORS Configuration
# In production, set ALLOWED_ORIGINS to the frontend domain (e.g., "https://your-app.railway.app")
# Multiple origins can be comma-separated.
allowed_origins_str = os.getenv("ALLOWED_ORIGINS", "http://localhost:8501")
allowed_origins = allowed_origins_str.split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

@app.get("/search", response_model=List[Seed])
def search_seeds(
    q: str = Query(..., min_length=1, description="Search query"),
    skip: int = Query(0, ge=0, description="Skip records"),
    limit: int = Query(50, ge=1, le=100, description="Max records to return"),
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
    try:
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
        ).offset(skip).limit(limit)
        results = db.exec(statement).all()
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/health")
def health_check():
    return {"status": "ok"}
