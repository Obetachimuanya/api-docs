#!/bin/bash

# API Documentation Converter Demo Script
# Demonstrates the tool's capabilities with various API documentation examples

set -e

echo "🎬 API Documentation to Markdown Converter - DEMO"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "\n${BLUE}📍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Ensure virtual environment is activated
if [[ "$VIRTUAL_ENV" == "" ]]; then
    print_info "Activating virtual environment..."
    source venv/bin/activate
fi

# Create demo output directory
DEMO_OUTPUT="./demo-output"
rm -rf "$DEMO_OUTPUT"
mkdir -p "$DEMO_OUTPUT"

print_step "Demo 1: Converting a simple REST API endpoint"
echo "URL: https://httpbin.org/get"
python api2md.py --url "https://httpbin.org/get" --output "$DEMO_OUTPUT/demo1"
print_success "Generated: $(ls $DEMO_OUTPUT/demo1/)"

print_step "Demo 2: Converting JSONPlaceholder API documentation"
echo "URL: https://jsonplaceholder.typicode.com/"
python api2md.py --url "https://jsonplaceholder.typicode.com/" --output "$DEMO_OUTPUT/demo2"
print_success "Generated: $(ls $DEMO_OUTPUT/demo2/)"

print_step "Demo 3: Batch processing multiple APIs"
echo "Processing URLs from examples/swagger-urls.txt"
python api2md.py --urls examples/swagger-urls.txt --output "$DEMO_OUTPUT/demo3"
print_success "Generated files:"
ls -la "$DEMO_OUTPUT/demo3/"

print_step "Demo 4: Converting Swagger Petstore documentation"
echo "URL: https://petstore.swagger.io/"
python api2md.py --url "https://petstore.swagger.io/" --output "$DEMO_OUTPUT/demo4"
print_success "Generated: $(ls $DEMO_OUTPUT/demo4/)"

echo ""
echo "🎉 Demo completed successfully!"
echo ""
echo "📁 All generated files are in: $DEMO_OUTPUT"
echo ""
echo "📊 Summary:"
echo "  - Demo 1: Simple API endpoint conversion"
echo "  - Demo 2: Full API documentation site"
echo "  - Demo 3: Batch processing multiple APIs"
echo "  - Demo 4: Swagger documentation"
echo ""

print_info "Sample content from JSONPlaceholder conversion:"
echo "----------------------------------------"
head -20 "$DEMO_OUTPUT/demo2"/*.md
echo "----------------------------------------"
echo ""

print_success "Demo completed! Check the generated files to see the conversion quality."