"""
Report generator for IaC Deprecation Scanner.

This module provides the ReportGenerator class that can output scan results
in multiple formats: console, HTML, Markdown, and JSON.
"""

import html
import json
import os
from datetime import datetime
from typing import Dict, List, Optional

from scanner.findings import Finding, ScanResult, Severity


class ReportGenerator:
    """
    Generate reports from scan results in multiple formats.
    
    Supports:
    - Console output (terminal-friendly with colors)
    - HTML (standalone file with embedded CSS)
    - Markdown (GitHub-compatible)
    - JSON (machine-readable)
    """
    
    def __init__(self, scan_result: ScanResult):
        """
        Initialize the report generator.
        
        Args:
            scan_result: The scan result to generate reports from
        """
        self.result = scan_result
        self._summary = scan_result.get_summary()
    
    def to_console(self, show_info: bool = False) -> None:
        """
        Print a formatted report to the console.
        
        Args:
            show_info: If True, include INFO-level findings
        """
        findings = self.result.findings
        
        # Filter out INFO findings if not requested
        if not show_info:
            findings = [f for f in findings if f.severity != Severity.INFO]
        
        print("\n" + "=" * 70)
        print("  🔍 IaC Deprecation Scan Report")
        print("=" * 70)
        
        print(f"\n📁 Repository: {self.result.repository_path}")
        print(f"📅 Scan Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"⏱️  Duration: {self._summary['scan_duration_seconds']:.2f}s")
        
        # Summary section
        print("\n" + "-" * 70)
        print("  SUMMARY")
        print("-" * 70)
        
        print(f"\n  Files Scanned: {self._summary['files_scanned']}")
        print(f"  Total Issues:  {self._summary['total_findings']}")
        
        # Severity breakdown
        print("\n  By Severity:")
        for sev in ["critical", "high", "medium", "low", "info"]:
            count = self._summary['by_severity'].get(sev, 0)
            emoji = {
                "critical": "🔴",
                "high": "🟠",
                "medium": "🟡",
                "low": "🔵",
                "info": "⚪",
            }[sev]
            print(f"    {emoji} {sev.upper():8}: {count}")
        
        # Category breakdown
        if self._summary.get('by_category'):
            print("\n  By Category:")
            for cat, count in sorted(self._summary['by_category'].items()):
                print(f"    • {cat}: {count}")
        
        # Findings by severity
        if not findings:
            print("\n✅ No deprecation issues found!")
        else:
            for severity in [Severity.CRITICAL, Severity.HIGH, Severity.MEDIUM, Severity.LOW, Severity.INFO]:
                if not show_info and severity == Severity.INFO:
                    continue
                
                sev_findings = [f for f in findings if f.severity == severity]
                if not sev_findings:
                    continue
                
                print("\n" + "-" * 70)
                print(f"  {severity.emoji} {severity.value.upper()} ({len(sev_findings)})")
                print("-" * 70)
                
                for finding in sev_findings:
                    print(f"\n  📄 {finding.file_path}:{finding.line_number}")
                    print(f"     {finding.title}")
                    if finding.description:
                        # Wrap long descriptions
                        desc = finding.description
                        if len(desc) > 60:
                            desc = desc[:60] + "..."
                        print(f"     {desc}")
                    if finding.suggested_fix:
                        fix = finding.suggested_fix
                        if len(fix) > 60:
                            fix = fix[:60] + "..."
                        print(f"     💡 Fix: {fix}")
        
        print("\n" + "=" * 70 + "\n")
    
    def to_html(self, output_path: str) -> None:
        """
        Generate a standalone HTML report.
        
        Args:
            output_path: Path to write the HTML file
        """
        findings = self.result.findings
        
        html_content = self._generate_html(findings)
        
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(html_content)
    
    def _generate_html(self, findings: List[Finding]) -> str:
        """Generate the HTML content."""
        
        severity_counts = self._summary['by_severity']
        
        # Group findings by severity
        findings_by_severity: Dict[Severity, List[Finding]] = {}
        for sev in Severity:
            findings_by_severity[sev] = [f for f in findings if f.severity == sev]
        
        html_parts = [
            """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IaC Deprecation Scan Report</title>
    <style>
        :root {
            --critical-color: #dc3545;
            --high-color: #fd7e14;
            --medium-color: #ffc107;
            --low-color: #17a2b8;
            --info-color: #6c757d;
            --bg-color: #f8f9fa;
            --card-bg: #ffffff;
            --text-color: #212529;
            --border-color: #dee2e6;
        }
        
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.6;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        header {
            text-align: center;
            padding: 30px 0;
            border-bottom: 2px solid var(--border-color);
            margin-bottom: 30px;
        }
        
        header h1 {
            font-size: 2rem;
            margin-bottom: 10px;
        }
        
        .meta-info {
            color: #6c757d;
            font-size: 0.9rem;
        }
        
        .summary-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .card {
            background: var(--card-bg);
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .card h3 {
            font-size: 2rem;
            margin-bottom: 5px;
        }
        
        .card p {
            font-size: 0.9rem;
            color: #6c757d;
        }
        
        .card.critical { border-left: 4px solid var(--critical-color); }
        .card.critical h3 { color: var(--critical-color); }
        
        .card.high { border-left: 4px solid var(--high-color); }
        .card.high h3 { color: var(--high-color); }
        
        .card.medium { border-left: 4px solid var(--medium-color); }
        .card.medium h3 { color: var(--medium-color); }
        
        .card.low { border-left: 4px solid var(--low-color); }
        .card.low h3 { color: var(--low-color); }
        
        .card.info { border-left: 4px solid var(--info-color); }
        .card.info h3 { color: var(--info-color); }
        
        .severity-section {
            margin-bottom: 30px;
        }
        
        .severity-header {
            padding: 15px 20px;
            border-radius: 8px 8px 0 0;
            color: white;
            font-size: 1.1rem;
        }
        
        .severity-header.critical { background: var(--critical-color); }
        .severity-header.high { background: var(--high-color); }
        .severity-header.medium { background: var(--medium-color); }
        .severity-header.low { background: var(--low-color); }
        .severity-header.info { background: var(--info-color); }
        
        .findings-table {
            width: 100%;
            border-collapse: collapse;
            background: var(--card-bg);
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .findings-table th,
        .findings-table td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }
        
        .findings-table th {
            background: #f1f3f5;
            font-weight: 600;
        }
        
        .findings-table tr:hover {
            background: #f8f9fa;
        }
        
        .location {
            font-family: 'SF Mono', 'Consolas', monospace;
            font-size: 0.85rem;
            color: #495057;
        }
        
        .fix {
            font-size: 0.85rem;
            color: #28a745;
        }
        
        .doc-link {
            font-size: 0.85rem;
        }
        
        .no-findings {
            text-align: center;
            padding: 50px;
            background: var(--card-bg);
            border-radius: 8px;
            color: #28a745;
            font-size: 1.2rem;
        }
        
        footer {
            text-align: center;
            padding: 20px;
            color: #6c757d;
            font-size: 0.85rem;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔍 IaC Deprecation Scan Report</h1>
            <p class="meta-info">
                Repository: """ + html.escape(self.result.repository_path) + """<br>
                Scanned: """ + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + """ |
                Files: """ + str(self._summary['files_scanned']) + """ |
                Duration: """ + f"{self._summary['scan_duration_seconds']:.2f}s" + """
            </p>
        </header>
        
        <section class="summary-cards">
            <div class="card critical">
                <h3>""" + str(severity_counts.get('critical', 0)) + """</h3>
                <p>Critical</p>
            </div>
            <div class="card high">
                <h3>""" + str(severity_counts.get('high', 0)) + """</h3>
                <p>High</p>
            </div>
            <div class="card medium">
                <h3>""" + str(severity_counts.get('medium', 0)) + """</h3>
                <p>Medium</p>
            </div>
            <div class="card low">
                <h3>""" + str(severity_counts.get('low', 0)) + """</h3>
                <p>Low</p>
            </div>
            <div class="card info">
                <h3>""" + str(severity_counts.get('info', 0)) + """</h3>
                <p>Info</p>
            </div>
        </section>
"""
        ]
        
        if not findings:
            html_parts.append("""
        <div class="no-findings">
            ✅ No deprecation issues found!
        </div>
""")
        else:
            for severity in [Severity.CRITICAL, Severity.HIGH, Severity.MEDIUM, Severity.LOW, Severity.INFO]:
                sev_findings = findings_by_severity[severity]
                if not sev_findings:
                    continue
                
                sev_name = severity.value
                html_parts.append(f"""
        <section class="severity-section">
            <div class="severity-header {sev_name}">
                {severity.emoji} {sev_name.upper()} ({len(sev_findings)})
            </div>
            <table class="findings-table">
                <thead>
                    <tr>
                        <th>Location</th>
                        <th>Issue</th>
                        <th>Category</th>
                        <th>Suggested Fix</th>
                    </tr>
                </thead>
                <tbody>
""")
                
                for finding in sev_findings:
                    doc_link = ""
                    if finding.documentation_url:
                        doc_link = f'<a href="{html.escape(finding.documentation_url)}" target="_blank">📚 Docs</a>'
                    
                    html_parts.append(f"""
                    <tr>
                        <td class="location">{html.escape(finding.file_path)}:{finding.line_number}</td>
                        <td>
                            <strong>{html.escape(finding.title)}</strong><br>
                            <small>{html.escape(finding.description or '')}</small>
                        </td>
                        <td>{html.escape(finding.category)}</td>
                        <td>
                            <span class="fix">{html.escape(finding.suggested_fix or '')}</span><br>
                            {doc_link}
                        </td>
                    </tr>
""")
                
                html_parts.append("""
                </tbody>
            </table>
        </section>
""")
        
        html_parts.append("""
        <footer>
            Generated by IaC Deprecation Scanner v1.0.0
        </footer>
    </div>
</body>
</html>
""")
        
        return "".join(html_parts)
    
    def to_markdown(self, output_path: str) -> None:
        """
        Generate a Markdown report.
        
        Args:
            output_path: Path to write the Markdown file
        """
        findings = self.result.findings
        
        md_parts = [
            "# 🔍 IaC Deprecation Scan Report\n\n",
            f"**Repository:** `{self.result.repository_path}`\n",
            f"**Scan Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n",
            f"**Duration:** {self._summary['scan_duration_seconds']:.2f}s\n\n",
            "---\n\n",
            "## Summary\n\n",
            f"| Metric | Value |\n",
            f"|--------|-------|\n",
            f"| Files Scanned | {self._summary['files_scanned']} |\n",
            f"| Total Issues | {self._summary['total_findings']} |\n",
            f"| 🔴 Critical | {self._summary['by_severity'].get('critical', 0)} |\n",
            f"| 🟠 High | {self._summary['by_severity'].get('high', 0)} |\n",
            f"| 🟡 Medium | {self._summary['by_severity'].get('medium', 0)} |\n",
            f"| 🔵 Low | {self._summary['by_severity'].get('low', 0)} |\n",
            f"| ⚪ Info | {self._summary['by_severity'].get('info', 0)} |\n\n",
        ]
        
        if not findings:
            md_parts.append("## ✅ No Issues Found\n\nNo deprecation issues were detected in this repository.\n")
        else:
            for severity in [Severity.CRITICAL, Severity.HIGH, Severity.MEDIUM, Severity.LOW, Severity.INFO]:
                sev_findings = [f for f in findings if f.severity == severity]
                if not sev_findings:
                    continue
                
                md_parts.append(f"## {severity.emoji} {severity.value.upper()} ({len(sev_findings)})\n\n")
                
                for finding in sev_findings:
                    md_parts.append(f"### {finding.title}\n\n")
                    md_parts.append(f"- **Location:** `{finding.file_path}:{finding.line_number}`\n")
                    md_parts.append(f"- **Category:** {finding.category}\n")
                    if finding.description:
                        md_parts.append(f"- **Description:** {finding.description}\n")
                    if finding.current_version:
                        md_parts.append(f"- **Current:** `{finding.current_version}`\n")
                    if finding.recommended_version:
                        md_parts.append(f"- **Recommended:** `{finding.recommended_version}`\n")
                    if finding.suggested_fix:
                        md_parts.append(f"- **Fix:** {finding.suggested_fix}\n")
                    if finding.documentation_url:
                        md_parts.append(f"- **Documentation:** [{finding.documentation_url}]({finding.documentation_url})\n")
                    md_parts.append("\n")
        
        md_parts.append("---\n\n")
        md_parts.append("*Generated by IaC Deprecation Scanner v1.0.0*\n")
        
        with open(output_path, "w", encoding="utf-8") as f:
            f.write("".join(md_parts))
    
    def to_json(self, output_path: str) -> None:
        """
        Generate a JSON report.
        
        Args:
            output_path: Path to write the JSON file
        """
        report_data = {
            "metadata": {
                "repository_path": self.result.repository_path,
                "scan_date": datetime.now().isoformat(),
                "scanner_version": self.result.scanner_version,
            },
            "summary": self._summary,
            "findings": [f.to_dict() for f in self.result.findings],
        }
        
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
