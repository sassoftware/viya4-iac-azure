#!/usr/bin/env python3
"""
Demo Script for IaC Deprecation Scanner

Run this script to demonstrate the scanner on the viya4-iac-azure repository.
"""

import os
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from scanner.core import DeprecationScanner
from scanner.report_generator import ReportGenerator


def main():
    """Run a demo scan."""
    
    # Determine the target repository
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_repo = os.path.join(os.path.dirname(script_dir), "viya4-iac-azure")
    
    # Check if target exists
    if not os.path.exists(target_repo):
        # Try relative path
        target_repo = os.path.join(script_dir, "..", "viya4-iac-azure")
    
    if not os.path.exists(target_repo):
        # Try going up from tools directory
        target_repo = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    
    if not os.path.exists(target_repo):
        print("Error: Could not find viya4-iac-azure repository")
        print(f"Looked in: {target_repo}")
        print("\nUsage: python demo.py [path_to_repo]")
        sys.exit(1)
    
    # Allow override from command line
    if len(sys.argv) > 1:
        target_repo = sys.argv[1]
    
    print("=" * 70)
    print("  🔍 IaC Deprecation Scanner - Demo")
    print("=" * 70)
    print(f"\nTarget Repository: {target_repo}")
    print("\nInitializing scanner...")
    
    # Create scanner (online mode to show API integration)
    scanner = DeprecationScanner(offline_mode=False, verbose=False)
    
    print("Running scan...\n")
    
    # Run scan
    result = scanner.scan_repository(target_repo)
    
    # Generate console report
    reporter = ReportGenerator(result)
    reporter.to_console(show_info=False)
    
    # Also generate HTML report
    html_output = os.path.join(script_dir, "demo_report.html")
    reporter.to_html(html_output)
    print(f"\n📄 HTML report saved to: {html_output}")
    
    # Generate Markdown report
    md_output = os.path.join(script_dir, "demo_report.md")
    reporter.to_markdown(md_output)
    print(f"📄 Markdown report saved to: {md_output}")
    
    # Generate JSON report
    json_output = os.path.join(script_dir, "demo_report.json")
    reporter.to_json(json_output)
    print(f"📄 JSON report saved to: {json_output}")
    
    print("\n" + "=" * 70)
    print("  Demo Complete!")
    print("=" * 70)
    
    # Summary
    summary = result.get_summary()
    print(f"""
Summary:
  • Files Scanned: {summary['files_scanned']}
  • Total Issues: {summary['total_findings']}
  • Critical: {summary['by_severity']['critical']}
  • High: {summary['by_severity']['high']}
  • Medium: {summary['by_severity']['medium']}
  • Low: {summary['by_severity']['low']}
  • Info: {summary['by_severity']['info']}
  • Scan Duration: {summary['scan_duration_seconds']:.2f}s
""")


if __name__ == "__main__":
    main()
