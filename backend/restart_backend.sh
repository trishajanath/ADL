#!/bin/bash

# User Authentication Implementation - Backend Restart Script
# This script will restart your backend server with the new authentication features

echo "🔄 Restarting ADL Backend with User Authentication..."
echo ""

cd "$(dirname "$0")"

# Check if virtual environment exists
if [ -d "venv" ]; then
    echo "📦 Using existing virtual environment..."
    source venv/bin/activate
elif [ -d ".venv" ]; then
    echo "📦 Using existing virtual environment..."
    source .venv/bin/activate
else
    echo "⚠️  No virtual environment found. Using system Python..."
fi

# Install any missing dependencies
echo "📥 Checking dependencies..."
pip3 install -q fastapi uvicorn google-auth python-dotenv

# Stop any existing instance
echo "🛑 Stopping any existing backend instances..."
pkill -f "uvicorn main:app" 2>/dev/null || true
pkill -f "python.*main.py" 2>/dev/null || true

sleep 2

# Start the server
echo ""
echo "🚀 Starting FastAPI server with user authentication..."
echo "📍 Server will be available at: http://127.0.0.1:8000"
echo ""
echo "✅ New features enabled:"
echo "   - User-specific project filtering"
echo "   - OAuth2 token authentication"
echo "   - Protected API endpoints"
echo ""
echo "Press Ctrl+C to stop the server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run the server
python3 main.py
