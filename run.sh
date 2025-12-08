#!/bin/bash
set -e

# 1. Ingest Data
# On Railway, persistent volume might be used, but for simplicity we re-ingest or skip if exists.
# The script handles "skip if exists" logic.
echo "Starting data ingestion..."
# Ensure PYTHONPATH is set so independent script runs work if not already set by Dockerfile
export PYTHONPATH=$PYTHONPATH:. 
python scripts/ingest_data.py

# 2. Start Backend (FastAPI) in background
# We bind to 0.0.0.0 (all interfaces) within the container.
# Railway internally routes traffic, but typically for a monolith we treat localhost communication.
# However, if we want to expose it properly or if we split services later, binding 0.0.0.0 is safe.
echo "Starting Backend..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 &

# 3. Start Frontend (Streamlit)
# Railway provides $PORT which the main app must listen on.
# We default to 8501 if PORT is not set (local dev).
PORT="${PORT:-8501}"
echo "Starting Frontend on port $PORT..."
streamlit run frontend/app.py --server.port $PORT --server.address 0.0.0.0
