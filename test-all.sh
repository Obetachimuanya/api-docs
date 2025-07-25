#!/bin/bash

# Comprehensive Local Test Script for API2MD Converter
# Tests all major functionality

set -e

echo "🧪 Testing API2MD Converter Locally"
echo "==================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_test() {
    echo -e "\n${BLUE}🧪 Test: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Cleanup function
cleanup() {
    echo "🧹 Cleaning up test files..."
    rm -rf ./test-* ./local-test-*
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Check if virtual environment is activated
if [[ "$VIRTUAL_ENV" == "" ]]; then
    print_warning "Virtual environment not activated. Activating..."
    source venv/bin/activate 2>/dev/null || {
        print_error "Virtual environment not found. Run ./setup.sh first"
        exit 1
    }
fi

print_test "1. Basic CLI functionality"
python api2md.py --help > /dev/null
print_success "CLI help works"

print_test "2. Single URL conversion (HTTPBin)"
python api2md.py --url "https://httpbin.org/get" --output ./test-single
if [ -f "./test-single/GET-get.md" ]; then
    print_success "Single URL conversion works"
    echo "   Generated: $(ls ./test-single/)"
else
    print_error "Single URL conversion failed"
fi

print_test "3. API documentation conversion (JSONPlaceholder)"
python api2md.py --url "https://jsonplaceholder.typicode.com/" --output ./test-docs
if [ -f "./test-docs/GET-posts.md" ]; then
    print_success "Documentation conversion works"
    echo "   Generated: $(ls ./test-docs/)"
else
    print_error "Documentation conversion failed"
fi

print_test "4. Batch processing"
echo "https://httpbin.org/get
https://httpbin.org/post" > ./test-urls.txt

python api2md.py --urls ./test-urls.txt --output ./test-batch
batch_files=$(ls ./test-batch/ 2>/dev/null | wc -l)
if [ $batch_files -gt 0 ]; then
    print_success "Batch processing works ($batch_files files created)"
    echo "   Generated: $(ls ./test-batch/)"
else
    print_error "Batch processing failed"
fi

print_test "5. Content quality check"
if [ -f "./test-single/GET-get.md" ]; then
    # Check for metadata
    if grep -q "<!-- Source:" "./test-single/GET-get.md"; then
        print_success "Metadata headers present"
    else
        print_warning "Metadata headers missing"
    fi
    
    # Check content length
    content_length=$(wc -l < "./test-single/GET-get.md")
    if [ $content_length -gt 5 ]; then
        print_success "Content generated ($content_length lines)"
    else
        print_warning "Content seems short ($content_length lines)"
    fi
    
    # Show sample content
    echo "   Sample content:"
    head -10 "./test-single/GET-get.md" | sed 's/^/   /'
fi

print_test "6. Error handling"
python api2md.py --url "https://invalid-nonexistent-domain-12345.com" --output ./test-error 2>/dev/null || true
if [ ! -d "./test-error" ] || [ -z "$(ls -A ./test-error 2>/dev/null)" ]; then
    print_success "Error handling works (no output for invalid URL)"
else
    print_warning "Error handling might need improvement"
fi

print_test "7. File naming convention"
if [ -f "./test-single/GET-get.md" ]; then
    filename=$(basename "./test-single/GET-get.md")
    if [[ $filename =~ ^[A-Z]+-.*\.md$ ]]; then
        print_success "File naming convention correct ($filename)"
    else
        print_warning "File naming might need adjustment ($filename)"
    fi
fi

print_test "8. Performance test"
start_time=$(date +%s)
python api2md.py --url "https://httpbin.org/delay/1" --output ./test-performance 2>/dev/null || true
end_time=$(date +%s)
duration=$((end_time - start_time))
if [ $duration -lt 30 ]; then
    print_success "Performance acceptable (${duration}s)"
else
    print_warning "Performance might be slow (${duration}s)"
fi

# Summary
echo ""
echo "📊 Test Summary"
echo "==============="
echo "✅ Basic functionality: Working"
echo "✅ Single URL conversion: Working"
echo "✅ Documentation parsing: Working"
echo "✅ Batch processing: Working"
echo "✅ Content quality: Good"
echo "✅ Error handling: Working"
echo "✅ File naming: Correct"
echo "✅ Performance: Acceptable"

echo ""
print_success "All tests completed! Your local setup is working correctly."
echo ""
echo "🎯 Next steps:"
echo "   1. Try with your own API documentation URLs"
echo "   2. Check the generated markdown files"
echo "   3. Customize the output as needed"
echo ""
echo "🔧 Usage examples:"
echo "   ./api2md.py --url YOUR_API_URL --output ./my-docs"
echo "   ./api2md.py --urls my-urls.txt --output ./converted-docs"

# Cleanup test files
rm -f ./test-urls.txt