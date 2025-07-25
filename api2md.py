#!/usr/bin/env python3
"""
API Documentation to Markdown Converter

Converts API documentation web pages into clean Markdown files, 
preserving parameters, code samples, and collapsible sections.

Usage:
    python api2md.py --urls urls.txt --output ./markdown
"""

import argparse
import asyncio
import os
import re
import sys
from pathlib import Path
from typing import List, Dict, Optional
from urllib.parse import urlparse, urljoin

from playwright.async_api import async_playwright, Page
from bs4 import BeautifulSoup, Comment
import markdownify


class APIDocConverter:
    """Main converter class for API documentation to Markdown"""
    
    def __init__(self, output_dir: str = './output'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
    
    async def expand_collapsibles(self, page: Page) -> None:
        """Expand all collapsible sections on the page"""
        try:
            # Common selectors for expand buttons
            expand_selectors = [
                'button[aria-expanded="false"]',
                '.expand-all',
                '[data-toggle="collapse"]',
                '.collapse-toggle',
                'details:not([open])',
                '.accordion-toggle',
                '[aria-label*="expand" i]',
                '[title*="expand" i]',
                'button:has-text("Expand")',
                'button:has-text("Show")',
                'a:has-text("Expand")',
                '.btn-expand'
            ]
            
            for selector in expand_selectors:
                try:
                    elements = await page.query_selector_all(selector)
                    for element in elements:
                        try:
                            if selector == 'details:not([open])':
                                await element.set_attribute('open', '')
                            else:
                                await element.click(timeout=1000)
                                await page.wait_for_timeout(500)
                        except Exception:
                            continue
                except Exception:
                    continue
            
            # Wait for any animations to complete
            await page.wait_for_timeout(2000)
            
        except Exception as e:
            print(f"Warning: Could not expand all collapsibles: {e}")
    
    def extract_endpoint_info(self, url: str, soup: BeautifulSoup) -> Dict[str, str]:
        """Extract endpoint method and path from the page"""
        method = 'GET'  # default
        endpoint = ''
        
        # Look for HTTP method indicators
        method_indicators = soup.find_all(['span', 'div', 'code', 'badge'], 
                                        string=re.compile(r'\b(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)\b', re.I))
        
        if method_indicators:
            method_text = method_indicators[0].get_text().strip().upper()
            for m in ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS']:
                if m in method_text:
                    method = m
                    break
        
        # Try to extract endpoint path
        path_patterns = [
            r'/api/[^"\s<>]+',
            r'/v\d+/[^"\s<>]+',
            r'https?://[^/]+(/[^"\s<>]+)',
            r'[^"\s<>]*(/[a-zA-Z0-9_\-/{}]+)',
        ]
        
        page_text = soup.get_text()
        for pattern in path_patterns:
            matches = re.findall(pattern, page_text)
            if matches:
                endpoint = matches[0]
                if isinstance(endpoint, tuple):
                    endpoint = endpoint[0]
                break
        
        # Clean up endpoint
        endpoint = re.sub(r'[^\w\-/{}]', '', endpoint) if endpoint else 'unknown'
        endpoint = endpoint.replace('/', '-').strip('-')
        
        return {'method': method, 'endpoint': endpoint}
    
    def clean_html_content(self, soup: BeautifulSoup) -> BeautifulSoup:
        """Clean and prepare HTML content for conversion"""
        # Remove comments
        for comment in soup.find_all(string=lambda text: isinstance(text, Comment)):
            comment.extract()
        
        # Remove navigation, header, footer elements
        for selector in ['nav', 'header', 'footer', '.nav', '.navbar', '.header', '.footer', 
                        '.sidebar', '.menu', '.breadcrumb', '.pagination', 'aside']:
            for element in soup.select(selector):
                element.decompose()
        
        # Remove script and style tags
        for tag in soup(['script', 'style', 'noscript']):
            tag.decompose()
        
        # Try to find main content area
        main_content = None
        content_selectors = [
            'main', '.content', '.main-content', '.documentation', 
            '.api-docs', '.doc-content', 'article', '.article',
            '#content', '#main', '#documentation'
        ]
        
        for selector in content_selectors:
            main_content = soup.select_one(selector)
            if main_content:
                break
        
        if main_content:
            # Create a new soup with just the main content
            new_soup = BeautifulSoup(str(main_content), 'html.parser')
            return new_soup
        
        return soup
    
    def generate_filename(self, method: str, endpoint: str, url: str) -> str:
        """Generate a clean filename for the markdown file"""
        if endpoint and endpoint != 'unknown':
            base_name = f"{method}-{endpoint}"
        else:
            # Fallback to URL-based naming
            parsed_url = urlparse(url)
            path_parts = [part for part in parsed_url.path.split('/') if part]
            if path_parts:
                base_name = f"{method}-{'-'.join(path_parts[-2:])}"
            else:
                base_name = f"{method}-{parsed_url.netloc.replace('.', '-')}"
        
        # Clean filename
        base_name = re.sub(r'[^\w\-]', '-', base_name)
        base_name = re.sub(r'-+', '-', base_name).strip('-')
        
        return f"{base_name}.md"
    
    async def scrape_page(self, url: str, page: Page) -> Optional[str]:
        """Scrape a single API documentation page"""
        try:
            print(f"Scraping: {url}")
            
            # Navigate to the page
            await page.goto(url, wait_until='networkidle', timeout=30000)
            
            # Expand collapsible sections
            await self.expand_collapsibles(page)
            
            # Get page content
            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')
            
            # Clean content
            cleaned_soup = self.clean_html_content(soup)
            
            # Extract endpoint info
            endpoint_info = self.extract_endpoint_info(url, cleaned_soup)
            
            # Convert to markdown
            markdown_content = markdownify.markdownify(
                str(cleaned_soup),
                strip=['script', 'style', 'meta', 'link', 'noscript'],
                heading_style='ATX'
            )
            
            # Clean up markdown
            markdown_content = re.sub(r'\n{3,}', '\n\n', markdown_content)
            markdown_content = markdown_content.strip()
            
            # Add metadata header
            metadata = f"<!-- Source: {url} -->\n"
            metadata += f"<!-- Method: {endpoint_info['method']} -->\n"
            metadata += f"<!-- Endpoint: {endpoint_info['endpoint']} -->\n\n"
            
            final_content = metadata + markdown_content
            
            # Generate filename and save
            filename = self.generate_filename(endpoint_info['method'], endpoint_info['endpoint'], url)
            filepath = self.output_dir / filename
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(final_content)
            
            print(f"Saved: {filepath}")
            return str(filepath)
            
        except Exception as e:
            print(f"Error scraping {url}: {e}")
            return None
    
    async def convert_urls(self, urls: List[str]) -> None:
        """Convert multiple URLs to markdown files"""
        async with async_playwright() as p:
            # Launch browser
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            )
            page = await context.new_page()
            
            successful_conversions = 0
            total_urls = len(urls)
            
            for url in urls:
                result = await self.scrape_page(url.strip(), page)
                if result:
                    successful_conversions += 1
            
            await browser.close()
            
            print(f"\nConversion complete!")
            print(f"Successfully converted: {successful_conversions}/{total_urls} URLs")
            print(f"Output directory: {self.output_dir.absolute()}")


def read_urls_file(filepath: str) -> List[str]:
    """Read URLs from a text file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip() and not line.strip().startswith('#')]
        return urls
    except FileNotFoundError:
        print(f"Error: URLs file '{filepath}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading URLs file: {e}")
        sys.exit(1)


def main():
    """Main CLI function"""
    parser = argparse.ArgumentParser(
        description='Convert API documentation web pages to clean Markdown files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python api2md.py --urls urls.txt --output ./markdown
  python api2md.py --url https://api.example.com/docs/endpoint1 --output ./docs
        """
    )
    
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--urls', type=str, help='Path to text file containing URLs (one per line)')
    group.add_argument('--url', type=str, help='Single URL to convert')
    
    parser.add_argument('--output', type=str, default='./output', 
                       help='Output directory for markdown files (default: ./output)')
    
    args = parser.parse_args()
    
    # Get URLs
    if args.urls:
        urls = read_urls_file(args.urls)
    else:
        urls = [args.url]
    
    if not urls:
        print("Error: No URLs to process.")
        sys.exit(1)
    
    print(f"Found {len(urls)} URL(s) to process")
    
    # Create converter and run
    converter = APIDocConverter(args.output)
    
    try:
        asyncio.run(converter.convert_urls(urls))
    except KeyboardInterrupt:
        print("\nConversion interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"Error during conversion: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()