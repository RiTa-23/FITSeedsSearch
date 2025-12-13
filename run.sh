#!/bin/bash
set -e

# Configure Streamlit via Environment Variables (Common configuration)
configure_streamlit() {
    local port=$1
    export STREAMLIT_SERVER_PORT="$port"
    export STREAMLIT_SERVER_ADDRESS="0.0.0.0"
    export STREAMLIT_SERVER_HEADLESS="true"
    export STREAMLIT_SERVER_ENABLE_CORS="false"
    export STREAMLIT_SERVER_ENABLE_XSRF_PROTECTION="false"
    export STREAMLIT_SERVER_FILE_WATCHER_TYPE="none"
}

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
    configure_streamlit "$PORT"
    
    exec streamlit run frontend/app.py

else
    echo "Starting Combined Service (Backend + Frontend)..."
    
    # Ingest Data
    echo "Starting data ingestion..."
    python scripts/ingest_data.py
    
    # 3. Determine Internal Backend Port
    # Ensure Internal Port doesn't conflict with the Public Port provided by Railway ($PORT)
    PORT="${PORT:-8501}"
    INTERNAL_PORT=8000
    if [ "$PORT" -eq "$INTERNAL_PORT" ]; then
        INTERNAL_PORT=8001
    fi
    echo "Public Port: $PORT"
    echo "Internal Backend Port: $INTERNAL_PORT"

    # Check for backend API URL availability
    # In combined mode, Frontend talks to Backend via localhost
    if [ -z "$API_URL" ]; then
        export API_URL="http://127.0.0.1:$INTERNAL_PORT/search"
    fi

    # Start Backend in background (Internal only)
    echo "Starting Backend on 127.0.0.1:$INTERNAL_PORT..."
    uvicorn app.main:app --host 127.0.0.1 --port "$INTERNAL_PORT" &
    # We rely on container shutdown to kill this, as we will exec streamlit next

    # Wait for backend
    echo "Waiting for backend..."
    for i in {1..30}; do
        if python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:$INTERNAL_PORT/health', timeout=2)" > /dev/null 2>&1; then
            echo "Backend is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "Backend failed to start"
            exit 1
        fi
        sleep 1
    done

    # Start Frontend (Publicly exposed)
    
    # Configure Streamlit via Environment Variables
    configure_streamlit "$PORT"

    echo "Starting Streamlit on 0.0.0.0:$PORT..."
    # Exec replaces the shell process with Streamlit, making it PID 1
    exec streamlit run frontend/app.py
fi
