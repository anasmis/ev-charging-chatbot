# Use a more recent Python image with better package support
FROM python:3.9-slim-bullseye

WORKDIR /app

# Install system dependencies required for Rasa and other packages
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    gcc \
    g++ \
    libffi-dev \
    libssl-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip to latest version
RUN pip install --upgrade pip

# Copy requirements and install Python dependencies in stages
COPY requirements.txt .

# Install dependencies with verbose output for debugging
RUN pip install --no-cache-dir --verbose -r requirements.txt

# Copy project files
COPY rasa/ ./rasa/
COPY web-interface/ ./web-interface/
COPY database/ ./database/

# Set environment variables
ENV PYTHONPATH=/app
ENV RASA_MODEL_PATH=/app/rasa/models

# Create startup script
COPY start-railway.sh .
RUN chmod +x start-railway.sh

# Expose ports
EXPOSE 5005 8080

# Health check
HEALTHCHECK --interval=60s --timeout=30s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:5005/webhooks/rest/health || exit 1

CMD ["./start-railway.sh"]