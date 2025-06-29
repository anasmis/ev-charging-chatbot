# PowerShell setup script for Windows
Write-Host "🚀 Setting up EV Charger Chatbot Project..." -ForegroundColor Green

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "📝 Creating .env file..." -ForegroundColor Yellow
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
    } else {
        Write-Host "⚠️  Please create .env file manually" -ForegroundColor Red
    }
}

# Create log directories
$logDirs = @("logs\rasa", "logs\n8n", "logs\whatsapp", "logs\postgres")
foreach ($dir in $logDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "📁 Created directory: $dir" -ForegroundColor Blue
    }
}

Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Edit .env file if needed" -ForegroundColor White
Write-Host "   2. Run: docker-compose up -d postgres redis" -ForegroundColor White
Write-Host "   3. Wait for database to be ready" -ForegroundColor White
Write-Host "   4. Run: docker-compose up -d n8n rasa-actions" -ForegroundColor White
Write-Host "   5. Set up your Rasa environment separately" -ForegroundColor White
Write-Host "   6. Check logs: docker-compose logs -f" -ForegroundColor White