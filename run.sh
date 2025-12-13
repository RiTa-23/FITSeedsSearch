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
    
    # Configure Streamlit via Environment Variables (More robust)
    export STREAMLIT_SERVER_PORT="$PORT"
    export STREAMLIT_SERVER_ADDRESS="0.0.0.0"
    export STREAMLIT_SERVER_HEADLESS="true"
    export STREAMLIT_SERVER_ENABLE_CORS="false"
    export STREAMLIT_SERVER_ENABLE_XSRF_PROTECTION="false"
    export STREAMLIT_SERVER_FILE_WATCHER_TYPE="none"
    
    exec streamlit run frontend/app.py

else
    echo "Starting Combined Service (Backend + Frontend)..."
    
    # Ingest Data
    echo "Starting data ingestion..."
    python scripts/ingest_data.py
    
    # Check for backend API URL availability
    # In combined mode, Frontend talks to Backend via localhost
    if [ -z "$API_URL" ]; then
        export API_URL="http://127.0.0.1:8000/search"
    fi

    # Start Backend in background (Internal only)
    # Listens on localhost:8000, not exposed to outside world
    echo "Starting Backend on 127.0.0.1:8000..."
    uvicorn app.main:app --host 127.0.0.1 --port 8000 &
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
        if python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" > /dev/null 2>&1; then
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

    # Start Frontend (Publicly exposed)
    # Streamlit listens on the port Railway provides ($PORT)
    PORT="${PORT:-8501}"
    
    # Configure Streamlit via Environment Variables
    export STREAMLIT_SERVER_PORT="$PORT"
    export STREAMLIT_SERVER_ADDRESS="0.0.0.0"
    export STREAMLIT_SERVER_HEADLESS="true"
    export STREAMLIT_SERVER_ENABLE_CORS="false"
    export STREAMLIT_SERVER_ENABLE_XSRF_PROTECTION="false"
    export STREAMLIT_SERVER_FILE_WATCHER_TYPE="none"

    echo "Starting Streamlit on 0.0.0.0:$PORT..."
    streamlit run frontend/app.py &
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
