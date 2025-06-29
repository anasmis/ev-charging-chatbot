#!/bin/bash

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting EV Charging Chatbot on Railway...${NC}"

# Set environment variables
export PYTHONPATH=/app
export ENVIRONMENT=${ENVIRONMENT:-production}

# Start Rasa actions server in background
echo -e "${YELLOW}📡 Starting Rasa Actions Server...${NC}"
cd /app/rasa
rasa run actions --port 5055 --auto-reload &
ACTIONS_PID=$!

# Wait a moment for actions server to start
sleep 5

# Start Rasa server
echo -e "${YELLOW}🤖 Starting Rasa Server...${NC}"
rasa run --enable-api --cors "*" --port 5005 --endpoints endpoints.yml &
RASA_PID=$!

# Wait a moment for Rasa server to start
sleep 10

# Start simple HTTP server for web interface
echo -e "${YELLOW}🌐 Starting Web Interface...${NC}"
cd /app/web-interface
python -m http.server 8080 &
WEB_PID=$!

# Function to cleanup on exit
cleanup() {
    echo -e "${RED}🛑 Shutting down services...${NC}"
    kill $ACTIONS_PID $RASA_PID $WEB_PID 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

echo -e "${GREEN}✅ All services started successfully!${NC}"
echo -e "${GREEN}🔌 Rasa API: http://localhost:5005${NC}"
echo -e "${GREEN}🌐 Web Interface: http://localhost:8080${NC}"
echo -e "${GREEN}📡 Actions Server: http://localhost:5055${NC}"

# Wait for all background processes
wait