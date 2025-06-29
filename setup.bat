@echo off
echo Setting up EV Charger Chatbot Project...

REM Create log directories
if not exist "logs" mkdir "logs"
if not exist "logs\rasa" mkdir "logs\rasa"
if not exist "logs\n8n" mkdir "logs\n8n"
if not exist "logs\whatsapp" mkdir "logs\whatsapp"
if not exist "logs\postgres" mkdir "logs\postgres"

REM Create other directories
if not exist "rasa\actions" mkdir "rasa\actions"
if not exist "rasa\data" mkdir "rasa\data"
if not exist "rasa\models" mkdir "rasa\models"

echo Setup complete!
echo.
echo Next steps:
echo 1. Make sure .env file exists and is configured
echo 2. Run: docker-compose up -d postgres redis
echo 3. Wait for database to be ready
echo 4. Run: docker-compose up -d n8n rasa-actions
echo.
pause