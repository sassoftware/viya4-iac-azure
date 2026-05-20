#!/usr/bin/env python3
"""
Integrated IaC Deprecation Scanner

Runs both:
1. IaC Scanner (comprehensive - Terraform, GitHub Actions, K8s, Docker, Shell)
2. Manifest Scanner (azurerm CHANGELOG deprecation check)

Generates a unified HTML report combining findings from both scanners.
"""

import json
import os
import subprocess
import sys
from datetime import datetime
from typing import Any, Dict, List, Optional

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from scanner.core import DeprecationScanner
from scanner.report_generator import ReportGenerator
from scanner.findings import ScanResult
from scanner.future_intelligence import build_future_deprecation_intelligence


def run_manifest_scanner(repo_root: str) -> Optional[Dict[str, Any]]:
    """
    Run the manifest-based azurerm CHANGELOG scanner.
    
    Args:
        repo_root: Path to repository root
        
    Returns:
        Parsed deprecation-report.json or None if failed
    """
    manifest_dir = os.path.join(repo_root, ".github", "tools", "manifest")
    generate_script = os.path.join(manifest_dir, "generate_manifest.py")
    check_script = os.path.join(manifest_dir, "check_deprecations.py")
    
    if not os.path.exists(generate_script) or not os.path.exists(check_script):
        print("⚠️  Manifest scanner scripts not found, skipping...")
        return None
    
    print("\n" + "-" * 70)
    print("  📋 Running Manifest Scanner (azurerm CHANGELOG)")
    print("-" * 70 + "\n")
    
    # Try to find Python interpreter
    python_cmd = None
    for cmd in ["py", "python3", "python"]:
        try:
            result = subprocess.run(
                [cmd, "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                python_cmd = cmd
                break
        except (subprocess.SubprocessError, FileNotFoundError):
            continue
    
    if not python_cmd:
        print("⚠️  Could not find Python interpreter for manifest scanner")
        return None
    
    # Run generate_manifest.py
    print("  → Refreshing manifest...")
    try:
        result = subprocess.run(
            [python_cmd, generate_script, "--root", repo_root],
            capture_output=True,
            text=True,
            timeout=60,
            cwd=repo_root
        )
        if result.returncode != 0:
            print(f"⚠️  Manifest generation failed: {result.stderr}")
            return None
    except subprocess.TimeoutExpired:
        print("⚠️  Manifest generation timed out")
        return None
    
    # Run check_deprecations.py
    print("  → Checking azurerm CHANGELOG...")
    try:
        result = subprocess.run(
            [python_cmd, check_script, "--root", repo_root],
            capture_output=True,
            text=True,
            timeout=120,
            cwd=repo_root
        )
        # This script may exit non-zero for REVIEW_REQUIRED, which is expected
    except subprocess.TimeoutExpired:
        print("⚠️  Deprecation check timed out")
        return None
    
    # Read the report
    report_path = os.path.join(repo_root, "deprecation-report.json")
    if os.path.exists(report_path):
        try:
            with open(report_path, "r", encoding="utf-8") as f:
                report = json.load(f)
            print(f"  ✓ Manifest scan complete")
            return report
        except (json.JSONDecodeError, IOError) as e:
            print(f"⚠️  Could not read deprecation report: {e}")
            return None
    else:
        print("⚠️  Deprecation report not generated")
        return None


def generate_integrated_html_report(
    iac_result: ScanResult,
    manifest_report: Optional[Dict[str, Any]],
    future_report: Optional[Dict[str, Any]],
    output_path: str,
    repo_path: str
) -> None:
    """Generate a unified HTML report combining both scanners."""
    
    summary = iac_result.get_summary()
    scan_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Build severity sections for IaC Scanner
    severity_order = ["critical", "high", "medium", "low", "info"]
    severity_icons = {
        "critical": "🔴",
        "high": "🟠", 
        "medium": "🟡",
        "low": "🔵",
        "info": "⚪"
    }
    
    iac_sections_html = ""
    for sev in severity_order:
        findings = [f for f in iac_result.findings if f.severity.name.lower() == sev]
        if not findings:
            continue
            
        rows = ""
        for f in findings:
            doc_link = ""
            if f.documentation_url:
                doc_link = f'<a href="{f.documentation_url}" target="_blank">📚 Docs</a>'
            
            rows += f"""
                <tr>
                    <td class="location">{f.file_path}:{f.line_number}</td>
                    <td>
                        <strong>{f.title}</strong><br>
                        <small>{f.description[:80]}{'...' if len(f.description) > 80 else ''}</small>
                    </td>
                    <td>{f.category}</td>
                    <td>
                        <span class="fix">{f.suggested_fix[:60]}{'...' if len(f.suggested_fix) > 60 else ''}</span><br>
                        {doc_link}
                    </td>
                </tr>
            """
        
        iac_sections_html += f"""
        <section class="severity-section">
            <div class="severity-header {sev}">
                {severity_icons[sev]} {sev.upper()} ({len(findings)})
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
                    {rows}
                </tbody>
            </table>
        </section>
        """
    
    # Build manifest scanner section
    manifest_html = ""
    if manifest_report:
        summary_data = manifest_report.get("summary", {})
        status = summary_data.get("status", "UNKNOWN")
        current_ver = summary_data.get("current_version", manifest_report.get("current_version", "?"))
        latest_ver = summary_data.get("latest_version", manifest_report.get("latest_version", "?"))
        breaking = summary_data.get("breaking_count", summary_data.get("breaking", 0))
        deprecated = summary_data.get("deprecated_count", summary_data.get("deprecated", 0))
        changed = summary_data.get("changed_count", summary_data.get("changed", 0))
        affected = manifest_report.get("affected_resources", [])
        
        status_badge = "✅ UP TO DATE" if status == "UP_TO_DATE" else "⚠️ REVIEW REQUIRED"
        status_class = "up-to-date" if status == "UP_TO_DATE" else "review-required"
        
        # Build affected resources table
        affected_rows = ""
        for res in affected[:20]:  # Limit to 20 for readability
            sev_icon = {"BREAKING": "🔴", "DEPRECATED": "🟡", "CHANGED": "🔵"}.get(res.get("severity", ""), "⚪")
            files = ", ".join(res.get("files", [])[:3])
            if len(res.get("files", [])) > 3:
                files += f" (+{len(res['files']) - 3} more)"
            note = res.get("lifecycle_note") or ""
            if len(note) > 100:
                note = note[:100] + "..."
            
            affected_rows += f"""
                <tr>
                    <td>{sev_icon} {res.get('severity', 'UNKNOWN')}</td>
                    <td><code>{res.get('resource_type', 'unknown')}</code></td>
                    <td class="location">{files}</td>
                    <td><small>{note}</small></td>
                </tr>
            """
        
        manifest_html = f"""
        <section class="manifest-section">
            <h2>📋 azurerm CHANGELOG Analysis</h2>
            <div class="manifest-summary {status_class}">
                <div class="manifest-status">{status_badge}</div>
                <div class="manifest-meta">
                    <strong>Version:</strong> {current_ver} → {latest_ver}
                </div>
            </div>
            
            <div class="manifest-counts">
                <div class="manifest-count breaking">
                    <span class="count">{breaking}</span>
                    <span class="label">🔴 BREAKING</span>
                </div>
                <div class="manifest-count deprecated">
                    <span class="count">{deprecated}</span>
                    <span class="label">🟡 DEPRECATED</span>
                </div>
                <div class="manifest-count changed">
                    <span class="count">{changed}</span>
                    <span class="label">🔵 CHANGED</span>
                </div>
            </div>
            
            {'<table class="findings-table"><thead><tr><th>Severity</th><th>Resource</th><th>Files</th><th>Note</th></tr></thead><tbody>' + affected_rows + '</tbody></table>' if affected_rows else '<p class="no-findings">No affected resources found</p>'}
            
            <p class="manifest-ref">
                <a href="https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md" target="_blank">
                    📚 View Full CHANGELOG
                </a>
            </p>
        </section>
        """
    else:
        manifest_html = """
        <section class="manifest-section">
            <h2>📋 azurerm CHANGELOG Analysis</h2>
            <p class="no-findings">Manifest scanner was not run or encountered an error.</p>
        </section>
        """

    # Build future deprecation intelligence section
    future_html = ""
    if future_report:
        upcoming_risks = future_report.get("upcoming_risks", [])
        summaries = future_report.get("upgrade_impact_summaries", [])
        metadata = future_report.get("metadata", {})

        risk_rows = ""
        for risk in upcoming_risks[:40]:
            source_link = ""
            if risk.get("source_url"):
                source_link = f'<a href="{risk.get("source_url")}" target="_blank">{risk.get("source", "Source")}</a>'
            else:
                source_link = risk.get("source", "")

            risk_rows += f"""
                <tr>
                    <td><strong>{risk.get('severity', 'INFO')}</strong></td>
                    <td>{risk.get('component', '')}</td>
                    <td><code>{risk.get('current_version', '')}</code></td>
                    <td>{risk.get('future_risk', '')}</td>
                    <td>{risk.get('effective_date', 'Upcoming')}</td>
                    <td>{risk.get('impact', '')}</td>
                    <td>{source_link}</td>
                </tr>
            """

        summary_html = ""
        if summaries:
            summary_items = "".join([f"<li>{s}</li>" for s in summaries])
            summary_html = f"""
            <div class="future-summary">
                <h3>Upgrade Impact Intelligence</h3>
                <ul>{summary_items}</ul>
            </div>
            """

        future_html = f"""
        <section class="future-section">
            <h2>🔮 Upcoming / Future Deprecation Risks</h2>
            <p class="future-meta">
                Generated: {metadata.get('generated_at', 'unknown')} |
                Cache Used: {metadata.get('cache_used', False)} |
                Risks: {len(upcoming_risks)}
            </p>
            {summary_html}
            {'<table class="findings-table"><thead><tr><th>Severity</th><th>Component</th><th>Current Version</th><th>Future Risk</th><th>Effective Date</th><th>Impact</th><th>Source</th></tr></thead><tbody>' + risk_rows + '</tbody></table>' if risk_rows else '<p class="no-findings">No upcoming risks detected from current intelligence sources.</p>'}
        </section>
        """
    else:
        future_html = """
        <section class="future-section">
            <h2>🔮 Upcoming / Future Deprecation Risks</h2>
            <p class="no-findings">Future deprecation intelligence was not available for this run.</p>
        </section>
        """
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IaC Deprecation Report - Integrated</title>
    <style>
        :root {{
            --critical-color: #dc3545;
            --high-color: #fd7e14;
            --medium-color: #ffc107;
            --low-color: #17a2b8;
            --info-color: #6c757d;
            --bg-color: #f8f9fa;
            --card-bg: #ffffff;
            --text-color: #212529;
            --border-color: #dee2e6;
            --success-color: #28a745;
        }}
        
        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.6;
            padding: 20px;
        }}
        
        .container {{
            max-width: 1400px;
            margin: 0 auto;
        }}
        
        header {{
            text-align: center;
            padding: 30px 0;
            border-bottom: 2px solid var(--border-color);
            margin-bottom: 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 8px;
            margin-top: -20px;
            margin-left: -20px;
            margin-right: -20px;
            padding-left: 20px;
            padding-right: 20px;
        }}
        
        header h1 {{
            font-size: 2.2rem;
            margin-bottom: 10px;
        }}
        
        .meta-info {{
            color: rgba(255,255,255,0.9);
            font-size: 0.9rem;
        }}
        
        .scanner-tabs {{
            display: flex;
            gap: 20px;
            margin-bottom: 30px;
        }}
        
        .scanner-tab {{
            flex: 1;
            background: var(--card-bg);
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        
        .scanner-tab h2 {{
            font-size: 1.3rem;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--border-color);
        }}
        
        .summary-cards {{
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 10px;
            margin-bottom: 20px;
        }}
        
        .card {{
            background: var(--card-bg);
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        
        .card h3 {{
            font-size: 1.8rem;
            margin-bottom: 3px;
        }}
        
        .card p {{
            font-size: 0.8rem;
            color: #6c757d;
        }}
        
        .card.critical {{ border-left: 4px solid var(--critical-color); }}
        .card.critical h3 {{ color: var(--critical-color); }}
        
        .card.high {{ border-left: 4px solid var(--high-color); }}
        .card.high h3 {{ color: var(--high-color); }}
        
        .card.medium {{ border-left: 4px solid var(--medium-color); }}
        .card.medium h3 {{ color: var(--medium-color); }}
        
        .card.low {{ border-left: 4px solid var(--low-color); }}
        .card.low h3 {{ color: var(--low-color); }}
        
        .card.info {{ border-left: 4px solid var(--info-color); }}
        .card.info h3 {{ color: var(--info-color); }}
        
        .severity-section {{
            margin-bottom: 25px;
        }}
        
        .severity-header {{
            padding: 12px 20px;
            border-radius: 8px 8px 0 0;
            color: white;
            font-size: 1rem;
            font-weight: 600;
        }}
        
        .severity-header.critical {{ background: var(--critical-color); }}
        .severity-header.high {{ background: var(--high-color); }}
        .severity-header.medium {{ background: var(--medium-color); }}
        .severity-header.low {{ background: var(--low-color); }}
        .severity-header.info {{ background: var(--info-color); }}
        
        .findings-table {{
            width: 100%;
            border-collapse: collapse;
            background: var(--card-bg);
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            font-size: 0.9rem;
        }}
        
        .findings-table th,
        .findings-table td {{
            padding: 10px 12px;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }}
        
        .findings-table th {{
            background: #f1f3f5;
            font-weight: 600;
        }}
        
        .findings-table tr:hover {{
            background: #f8f9fa;
        }}
        
        .location {{
            font-family: 'SF Mono', 'Consolas', monospace;
            font-size: 0.8rem;
            color: #495057;
        }}
        
        .fix {{
            font-size: 0.8rem;
            color: var(--success-color);
        }}
        
        code {{
            background: #e9ecef;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'SF Mono', 'Consolas', monospace;
            font-size: 0.85rem;
        }}
        
        /* Manifest Section Styles */
        .manifest-section {{
            background: var(--card-bg);
            border-radius: 8px;
            padding: 25px;
            margin-top: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        
        .manifest-section h2 {{
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--border-color);
        }}
        
        .manifest-summary {{
            display: flex;
            align-items: center;
            gap: 20px;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }}
        
        .manifest-summary.up-to-date {{
            background: #d4edda;
            border: 1px solid #c3e6cb;
        }}
        
        .manifest-summary.review-required {{
            background: #fff3cd;
            border: 1px solid #ffeeba;
        }}
        
        .manifest-status {{
            font-size: 1.2rem;
            font-weight: 600;
        }}
        
        .manifest-counts {{
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
        }}
        
        .manifest-count {{
            flex: 1;
            text-align: center;
            padding: 15px;
            border-radius: 8px;
            background: #f8f9fa;
        }}
        
        .manifest-count .count {{
            font-size: 2rem;
            font-weight: 700;
            display: block;
        }}
        
        .manifest-count .label {{
            font-size: 0.85rem;
            color: #6c757d;
        }}
        
        .manifest-count.breaking .count {{ color: var(--critical-color); }}
        .manifest-count.deprecated .count {{ color: var(--medium-color); }}
        .manifest-count.changed .count {{ color: var(--low-color); }}
        
        .manifest-ref {{
            margin-top: 20px;
            text-align: center;
        }}

        /* Future intelligence section */
        .future-section {{
            background: var(--card-bg);
            border-radius: 8px;
            padding: 25px;
            margin-top: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}

        .future-section h2 {{
            margin-bottom: 12px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--border-color);
        }}

        .future-meta {{
            color: #6c757d;
            font-size: 0.85rem;
            margin-bottom: 14px;
        }}

        .future-summary {{
            margin-bottom: 16px;
            padding: 12px;
            background: #f8f9fa;
            border: 1px solid var(--border-color);
            border-radius: 8px;
        }}

        .future-summary h3 {{
            font-size: 1rem;
            margin-bottom: 8px;
        }}

        .future-summary ul {{
            margin-left: 20px;
        }}
        
        .no-findings {{
            text-align: center;
            padding: 30px;
            background: #f8f9fa;
            border-radius: 8px;
            color: #6c757d;
        }}
        
        footer {{
            text-align: center;
            padding: 20px;
            color: #6c757d;
            font-size: 0.85rem;
            margin-top: 30px;
            border-top: 1px solid var(--border-color);
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔍 IaC Deprecation Report — Integrated</h1>
            <p class="meta-info">
                Repository: {repo_path}<br>
                Generated: {scan_date} |
                Files Scanned: {summary['files_scanned']} |
                Duration: {summary['scan_duration_seconds']:.2f}s
            </p>
        </header>
        
        <div class="scanner-tab">
            <h2>🛠️ IaC Scanner — Pattern-Based Analysis</h2>
            <p style="margin-bottom:15px;color:#6c757d;">Scans Terraform, GitHub Actions, Kubernetes, Docker, and Shell scripts for deprecated patterns.</p>
            
            <section class="summary-cards">
                <div class="card critical">
                    <h3>{summary['by_severity']['critical']}</h3>
                    <p>Critical</p>
                </div>
                <div class="card high">
                    <h3>{summary['by_severity']['high']}</h3>
                    <p>High</p>
                </div>
                <div class="card medium">
                    <h3>{summary['by_severity']['medium']}</h3>
                    <p>Medium</p>
                </div>
                <div class="card low">
                    <h3>{summary['by_severity']['low']}</h3>
                    <p>Low</p>
                </div>
                <div class="card info">
                    <h3>{summary['by_severity']['info']}</h3>
                    <p>Info</p>
                </div>
            </section>
            
            {iac_sections_html if iac_sections_html else '<p class="no-findings">✅ No issues found!</p>'}
        </div>
        
        {manifest_html}

        {future_html}
        
        <footer>
            Generated by IaC Deprecation Scanner v1.0.0 — Integrated Report
        </footer>
    </div>
</body>
</html>
"""
    
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)


def main():
    """Run the integrated IaC deprecation scan."""
    
    # Determine the target repository
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_repo = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    
    # Allow override from command line
    if len(sys.argv) > 1:
        target_repo = sys.argv[1]
    
    if not os.path.exists(target_repo):
        print(f"Error: Repository not found: {target_repo}")
        sys.exit(1)
    
    print("=" * 70)
    print("  🔍 IaC Deprecation Scanner — Integrated Report")
    print("=" * 70)
    print(f"\nRepository: {target_repo}")
    print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # =========================================================================
    # Scanner 1: IaC Scanner (Pattern-Based)
    # =========================================================================
    print("\n" + "-" * 70)
    print("  🛠️  Running IaC Scanner (Pattern-Based)")
    print("-" * 70 + "\n")
    
    scanner = DeprecationScanner(offline_mode=False, verbose=False)
    iac_result = scanner.scan_repository(target_repo)
    
    # Print console summary
    reporter = ReportGenerator(iac_result)
    reporter.to_console(show_info=False)
    
    # =========================================================================
    # Scanner 2: Manifest Scanner (azurerm CHANGELOG)
    # =========================================================================
    manifest_report = run_manifest_scanner(target_repo)

    # =========================================================================
    # Scanner 3: Future Deprecation Intelligence
    # =========================================================================
    print("\n" + "-" * 70)
    print("  🔮 Running Future Deprecation Intelligence")
    print("-" * 70 + "\n")

    future_report = build_future_deprecation_intelligence(
        repo_root=target_repo,
        scanner_root=script_dir,
        manifest_report=manifest_report,
    )

    print(f"  ✓ Future intelligence complete ({len(future_report.get('upcoming_risks', []))} risks)")
    
    # =========================================================================
    # Generate Integrated Report
    # =========================================================================
    print("\n" + "-" * 70)
    print("  📄 Generating Integrated Report")
    print("-" * 70 + "\n")
    
    # Save reports to repo root (not scanner dir)
    html_output = os.path.join(target_repo, "iac-deprecation-report.html")
    generate_integrated_html_report(iac_result, manifest_report, future_report, html_output, target_repo)
    print(f"  ✓ HTML report: {html_output}")
    
    # Also save JSON
    json_output = os.path.join(target_repo, "iac-deprecation-report.json")
    combined_json = {
        "generated_at": datetime.now().isoformat(),
        "repository": target_repo,
        "iac_scanner": iac_result.get_summary(),
        "iac_scanner_findings": [
            {
                "file": f.file_path,
                "line": f.line_number,
                "severity": f.severity.name,
                "category": f.category,
                "title": f.title,
                "description": f.description,
                "suggested_fix": f.suggested_fix,
                "documentation_url": f.documentation_url,
            }
            for f in iac_result.findings
        ],
        "manifest_scanner": manifest_report,
        "future_deprecation_intelligence": future_report,
    }
    with open(json_output, "w", encoding="utf-8") as f:
        json.dump(combined_json, f, indent=2, default=str)
    print(f"  ✓ JSON report: {json_output}")
    
    # Summary
    print("\n" + "=" * 70)
    print("  ✅ Integrated Scan Complete!")
    print("=" * 70)
    
    summary = iac_result.get_summary()
    print(f"""
IaC Scanner:
  • Files Scanned: {summary['files_scanned']}
  • Total Issues: {summary['total_findings']}
  • Critical: {summary['by_severity']['critical']}
  • High: {summary['by_severity']['high']}
  • Medium: {summary['by_severity']['medium']}
  • Low: {summary['by_severity']['low']}
""")
    
    if manifest_report:
        ms = manifest_report.get("summary", {})
        curr_ver = ms.get('current_version', manifest_report.get('current_version', '?'))
        lat_ver = ms.get('latest_version', manifest_report.get('latest_version', '?'))
        print(f"""Manifest Scanner (azurerm {curr_ver} → {lat_ver}):
  • Status: {ms.get('status', 'UNKNOWN')}
  • Breaking: {ms.get('breaking_count', ms.get('breaking', 0))}
  • Deprecated: {ms.get('deprecated_count', ms.get('deprecated', 0))}
  • Changed: {ms.get('changed_count', ms.get('changed', 0))}
""")

        if future_report:
                print(f"""Future Intelligence:
    • Upcoming Risks: {len(future_report.get('upcoming_risks', []))}
    • Sources: {len(future_report.get('metadata', {}).get('sources', []))}
    • Cache Used: {future_report.get('metadata', {}).get('cache_used', False)}
""")
    
    print(f"Reports saved to:\n  • {html_output}\n  • {json_output}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
