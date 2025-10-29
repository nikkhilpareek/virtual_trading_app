#!/bin/bash

# Stonks Trading API - Quick Start Script
# This script starts the FastAPI backend server

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

# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
