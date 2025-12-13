# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

WORKDIR /app
ENV PYTHONPATH=/app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy the lockfile and pyproject.toml
COPY uv.lock pyproject.toml /app/

# Install the project's dependencies using the lockfile and settings
RUN uv sync --frozen --no-install-project --no-dev

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Copy the project into the image
COPY . /app

# Install the project itself
RUN uv sync --frozen --no-dev

# Expose default port
EXPOSE 8000
EXPOSE 8501

RUN chmod +x run.sh

CMD ["./run.sh"]
