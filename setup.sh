#!/bin/bash

# API Documentation to Markdown Converter Setup Script
# This script installs dependencies and runs a quick test

set -e  # Exit on any error

echo "🚀 Setting up API Documentation to Markdown Converter..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is required but not installed. Please install Python 3.7+ and try again."
    exit 1
fi

print_status "Python 3 found: $(python3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    print_status "Virtual environment created"
else
    print_status "Virtual environment already exists"
fi

# Activate virtual environment and install dependencies
echo "📦 Installing Python dependencies..."
source venv/bin/activate

if pip install -r requirements.txt; then
    print_status "Python dependencies installed successfully"
else
    print_error "Failed to install Python dependencies"
    exit 1
fi

# Install Playwright browsers
echo "🌐 Installing Playwright browsers..."
if playwright install chromium; then
    print_status "Playwright browsers installed successfully"
else
    print_error "Failed to install Playwright browsers"
    exit 1
fi

# Make the script executable
chmod +x api2md.py
print_status "Scripts made executable"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "🧪 Running a quick test..."

# Test with a simple URL
echo "Testing with httpbin.org..."
if python api2md.py --url "https://httpbin.org/get" --output ./test-output; then
    print_status "Test completed successfully!"
    echo "📁 Check the './test-output' directory for generated files"
    
    # Show what was generated
    if [ -d "./test-output" ]; then
        echo ""
        echo "Generated files:"
        ls -la ./test-output/
    fi
else
    print_warning "Test had some issues, but setup is likely complete"
fi

echo ""
echo "🔧 Usage Examples:"
echo "  # Convert a single URL:"
echo "  ./api2md.py --url https://api.example.com/docs/endpoint1 --output ./markdown"
echo ""
echo "  # Convert multiple URLs from a file:"
echo "  ./api2md.py --urls urls.txt --output ./markdown"
echo ""
echo "  # With virtual environment activated:"
echo "  source venv/bin/activate"
echo "  python api2md.py --urls examples/swagger-urls.txt --output ./docs"
echo ""
print_status "Ready to use! See README.md for complete documentation"