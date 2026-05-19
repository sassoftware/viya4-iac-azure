"""
IaC Deprecation Scanner Package

A deterministic scanner for detecting deprecated patterns in Infrastructure as Code files.
Supports Terraform, Kubernetes YAML, Dockerfiles, GitHub Actions, and shell scripts.

Usage:
    from scanner.core import DeprecationScanner
    from scanner.report_generator import ReportGenerator

    scanner = DeprecationScanner()
    result = scanner.scan_repository("/path/to/repo")

    reporter = ReportGenerator(result)
    reporter.to_console()
    reporter.to_html("report.html")
"""

__version__ = "1.0.0"
__author__ = "PSCLOUD Infrastructure Team"

from scanner.findings import Finding, ScanResult, Severity
from scanner.core import DeprecationScanner
from scanner.report_generator import ReportGenerator

__all__ = [
    "DeprecationScanner",
    "ReportGenerator",
    "Finding",
    "ScanResult",
    "Severity",
]
