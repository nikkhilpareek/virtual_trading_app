#!/bin/bash

# Stonks Trading API - Quick Start Script
# This script starts the FastAPI backend server

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the backend directory
cd "$SCRIPT_DIR"

echo "🚀 Starting Stonks Trading API Backend..."
echo ""
echo "📍 Server will be available at:"
echo "   - http://localhost:8000"
echo "   - http://0.0.0.0:8000"
echo ""
echo "📖 API Documentation will be at:"
echo "   - http://localhost:8000/docs (Swagger UI)"
echo "   - http://localhost:8000/redoc (ReDoc)"
echo ""
echo "⚡ Press CTRL+C to stop the server"
echo ""
echo "═══════════════════════════════════════════════════"
echo ""

# Activate virtual environment
source venv/bin/activate

# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
