# API Documentation to Markdown Converter

A powerful tool that converts API documentation web pages into clean, well-formatted Markdown files. Perfect for archiving documentation, creating offline references, or migrating documentation formats.

## Features

- **JavaScript-Rendered Content**: Uses Playwright to handle dynamically loaded content
- **Collapsible Sections**: Automatically expands all collapsible sections and accordions
- **Smart Content Extraction**: Focuses on main documentation content, filtering out navigation and UI elements
- **Enhanced Markdown Conversion**: 
  - Preserves code blocks with language detection
  - Converts HTML tables to proper Markdown tables
  - Maintains formatting for parameters and descriptions
- **Intelligent File Naming**: Generates descriptive filenames based on HTTP methods and endpoints
- **Metadata Preservation**: Includes source URL and endpoint information in each file
- **Batch Processing**: Process multiple URLs from a text file
- **Clean Output**: Organized output with one file per endpoint

## Installation

### Prerequisites

- Python 3.7 or higher
- pip (Python package installer)

### Setup

1. **Clone or download the project files**
   ```bash
   # If you have the files in a directory
   cd api2md-converter
   ```

2. **Install Python dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Install Playwright browsers**
   ```bash
   playwright install chromium
   ```

## Usage

### Basic Usage

#### Convert a single URL
```bash
python api2md.py --url https://api.example.com/docs/endpoint1 --output ./markdown
```

#### Convert multiple URLs from a file
```bash
python api2md.py --urls urls.txt --output ./markdown
```

### Command Line Options

```
usage: api2md.py [-h] (--urls URLS | --url URL) [--output OUTPUT]

Convert API documentation web pages to clean Markdown files

optional arguments:
  -h, --help       show this help message and exit
  --urls URLS      Path to text file containing URLs (one per line)
  --url URL        Single URL to convert
  --output OUTPUT  Output directory for markdown files (default: ./output)

Examples:
  python api2md.py --urls urls.txt --output ./markdown
  python api2md.py --url https://api.example.com/docs/endpoint1 --output ./docs
```

### URLs File Format

Create a text file with one URL per line. Lines starting with `#` are treated as comments:

```txt
# My API Documentation URLs
https://api.example.com/docs/users/get
https://api.example.com/docs/users/create
https://api.example.com/docs/posts/list

# Another API
https://another-api.com/docs/authenticate
```

## Output Format

### File Naming Convention

Generated files follow this pattern:
- `GET-users.md` - GET endpoint for users
- `POST-users-create.md` - POST endpoint for creating users
- `DELETE-posts-123.md` - DELETE endpoint for specific post

### Markdown Structure

Each generated file includes:

1. **Metadata Header** (HTML comments)
   ```html
   <!-- Source: https://api.example.com/docs/endpoint -->
   <!-- Method: GET -->
   <!-- Endpoint: users -->
   ```

2. **Clean Documentation Content**
   - Method descriptions
   - Parameter tables
   - Code examples with syntax highlighting
   - Response schemas
   - Error codes and descriptions

### Example Output

```markdown
<!-- Source: https://api.example.com/docs/users/get -->
<!-- Method: GET -->
<!-- Endpoint: users -->

# Get Users

Retrieve a list of all users in the system.

## Parameters

| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| limit     | int    | No       | Maximum number of users to return |
| offset    | int    | No       | Number of users to skip |

## Request Example

```bash
curl -X GET "https://api.example.com/users?limit=10&offset=0" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Response Example

```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  ],
  "total": 100
}
```
```

## Advanced Features

### Content Cleaning

The tool automatically:
- Removes navigation menus, headers, and footers
- Strips out JavaScript and CSS
- Focuses on main documentation content
- Preserves important structural elements

### Collapsible Section Handling

Automatically expands:
- Accordion panels
- Collapsible code examples
- Hidden parameter details
- Dropdown menus

### Table Conversion

HTML tables are converted to proper Markdown tables:

```markdown
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id   | int  | Yes      | User identifier |
| name      | str  | Yes      | User full name |
```

### Code Block Enhancement

- Detects programming language from CSS classes
- Preserves syntax highlighting markers
- Handles both inline `code` and block code

## Troubleshooting

### Common Issues

1. **"playwright not found" error**
   ```bash
   pip install playwright
   playwright install chromium
   ```

2. **Timeout errors for slow-loading pages**
   - The tool waits up to 30 seconds for pages to load
   - Try running again or check if the URL is accessible

3. **Empty or incomplete output**
   - Some sites may block automated access
   - Try different URLs or check if the site requires authentication

4. **Installation issues**
   ```bash
   # Update pip first
   pip install --upgrade pip
   
   # Then install requirements
   pip install -r requirements.txt
   ```

### Debug Mode

For troubleshooting, you can modify the script to run in non-headless mode by changing:
```python
browser = await p.chromium.launch(headless=False)  # Set to False for debugging
```

## Technical Details

### Dependencies

- **playwright**: Web scraping and browser automation
- **beautifulsoup4**: HTML parsing and content extraction
- **markdownify**: HTML to Markdown conversion
- **lxml**: Fast XML/HTML processing
- **requests**: HTTP requests (for fallback scenarios)

### Architecture

1. **Web Scraping Layer**: Playwright handles JavaScript-rendered content
2. **Content Processing**: BeautifulSoup cleans and structures HTML
3. **Conversion Engine**: Custom MarkdownConverter with API documentation optimizations
4. **Output Management**: Intelligent file naming and organization

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is provided as-is for educational and personal use.