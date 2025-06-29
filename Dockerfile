# Multi-stage build for Railway deployment
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Rasa project
COPY rasa/ ./rasa/
COPY web-interface/ ./web-interface/

# Set environment variables
ENV PYTHONPATH=/app
ENV RASA_MODEL_PATH=/app/rasa/models

# Pre-train the Rasa model to reduce startup time
WORKDIR /app/rasa
RUN rasa train --fixed-model-name chatbot-model

# Create startup script
WORKDIR /app
COPY start-railway.sh .
RUN chmod +x start-railway.sh

# Expose ports
EXPOSE 5005 8080

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5005/webhooks/rest/webhook || exit 1

CMD ["./start-railway.sh"]