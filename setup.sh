#!/bin/bash

# API Documentation to Markdown Converter Setup Script
# This script installs dependencies and runs a quick test

echo "🚀 Setting up API Documentation to Markdown Converter..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed. Please install Python 3.7+ and try again."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
if pip3 install -r requirements.txt; then
    echo "✅ Python dependencies installed successfully"
else
    echo "❌ Failed to install Python dependencies"
    exit 1
fi

# Install Playwright browsers
echo "🌐 Installing Playwright browsers..."
if python3 -m playwright install chromium; then
    echo "✅ Playwright browsers installed successfully"
else
    echo "❌ Failed to install Playwright browsers"
    exit 1
fi

# Make the script executable
chmod +x api2md.py

echo "🎉 Setup complete!"
echo ""
echo "🧪 Running a quick test..."

# Test with a simple URL
echo "Testing with httpbin.org..."
if python3 api2md.py --url "https://httpbin.org/get" --output ./test-output; then
    echo "✅ Test completed successfully!"
    echo "📁 Check the './test-output' directory for generated files"
else
    echo "⚠️  Test had some issues, but setup is likely complete"
fi

echo ""
echo "🔧 Usage Examples:"
echo "  python3 api2md.py --url https://api.example.com/docs/endpoint1 --output ./markdown"
echo "  python3 api2md.py --urls urls.txt --output ./markdown"
echo ""
echo "📖 See README.md for complete documentation"