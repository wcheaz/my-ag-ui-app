FROM python:3.12-slim

WORKDIR /app

# Create non-root user for security
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 appuser && \
    mkdir -p /home/appuser && chown appuser:appgroup /home/appuser

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy dependency definitions
COPY pyproject.toml uv.lock ./

# Install curl for diagnostics and dependencies
RUN apt-get update && apt-get install -y curl && \
    uv sync --frozen --no-install-project

# Copy agent source code
COPY . .

# Install the project itself and set permissions for non-root user
RUN uv sync --frozen && \
    chown -R appuser:appgroup /app

# Switch to non-root user
ENV HOME=/home/appuser
USER appuser

EXPOSE 8000

# Run the agent
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
