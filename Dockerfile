FROM python:3.12-slim

WORKDIR /app
ENV PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml .
RUN pip install --no-cache-dir .

COPY . .

# Expose default port (Railway overrides this with $PORT but good to have)
EXPOSE 7860

RUN chmod +x run.sh

CMD ["./run.sh"]
