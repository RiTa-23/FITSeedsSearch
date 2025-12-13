#!/bin/bash
set -e

# 2. Decide what to run based on SERVICE_TYPE
SERVICE_TYPE="${SERVICE_TYPE:-combined}"
echo "SERVICE_TYPE: $SERVICE_TYPE"

if [ "$SERVICE_TYPE" = "backend" ]; then
    echo "Starting Backend-only mode..."
    
    # Ingest Data
    echo "Starting data ingestion..."
    python scripts/ingest_data.py

    # Configured for Railway default listening
    exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"

elif [ "$SERVICE_TYPE" = "frontend" ]; then
    echo "Starting Frontend-only mode..."
    PORT="${PORT:-8501}"
    echo "Frontend listening on port: $PORT"
    exec streamlit run frontend/app.py \
        --server.port "$PORT" \
        --server.address 0.0.0.0 \
        --server.headless true \
        --server.enableCORS false \
        --server.enableXsrfProtection false

else
    echo "Starting Combined mode (Legacy for local dev)..."
    
    # Ingest Data
    echo "Starting data ingestion..."
    python scripts/ingest_data.py
    
    # Check for backend API URL availability
    if [ -z "$API_URL" ]; then
        export API_URL="http://localhost:8000/search"
    fi

    # Start Backend in background
    uvicorn app.main:app --host 0.0.0.0 --port 8000 &
    BACKEND_PID=$!

    # Cleanup function to kill both processes
    cleanup() {
        echo "Stopping processes..."
        kill "$BACKEND_PID" 2>/dev/null || true
        kill "$FRONTEND_PID" 2>/dev/null || true
    }

    # Trap for cleanup on exit or signal
    trap 'cleanup; exit' SIGTERM SIGINT EXIT

    # Wait for backend
    echo "Waiting for backend..."
    for i in {1..30}; do
        if curl -f http://localhost:8000/health > /dev/null 2>&1; then
            echo "Backend is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "Backend failed to start"
            cleanup
            exit 1
        fi
        if ! kill -0 $BACKEND_PID 2>/dev/null; then
             echo "Backend process died while starting"
             cleanup
             exit 1
        fi
        sleep 1
    done

    # Start Frontend
    PORT="${PORT:-8501}"
    streamlit run frontend/app.py --server.port "$PORT" --server.address 0.0.0.0 &
    FRONTEND_PID=$!
    
    # Wait for any process to exit
    # bash's wait -n waits for the next job to finish
    # If either backend or frontend exits/crashes, we want to stop the other.
    echo "Monitoring processes..."
    wait -n $BACKEND_PID $FRONTEND_PID
    
    echo "One of the processes exited unexpectedly."
    # The 'trap ... EXIT' will handle the cleanup automatically when this script exits
    exit 1
fi
