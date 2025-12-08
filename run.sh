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
BACKEND_PID=$!

# Trap SIGTERM and SIGINT to gracefully shutdown both processes
trap 'kill $BACKEND_PID; exit' SIGTERM SIGINT

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
for i in {1..30}; do
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo "Backend is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Backend failed to start"
        kill $BACKEND_PID
        exit 1
    fi
    sleep 1
done

# 3. Start Frontend (Streamlit)
# Railway provides $PORT which the main app must listen on.
# We default to 8501 if PORT is not set (local dev).
PORT="${PORT:-8501}"
echo "Starting Frontend on port $PORT..."
streamlit run frontend/app.py --server.port $PORT --server.address 0.0.0.0
