"""
Finding and ScanResult data models for the IaC Deprecation Scanner.

This module defines the core data structures used to represent scan findings
and aggregated scan results.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional


class Severity(Enum):
    """Severity levels for deprecation findings."""
    
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"
    
    def __lt__(self, other: "Severity") -> bool:
        """Enable sorting by severity (critical first)."""
        order = [Severity.CRITICAL, Severity.HIGH, Severity.MEDIUM, Severity.LOW, Severity.INFO]
        return order.index(self) < order.index(other)
    
    @property
    def emoji(self) -> str:
        """Return an emoji representation for the severity."""
        return {
            Severity.CRITICAL: "🔴",
            Severity.HIGH: "🟠",
            Severity.MEDIUM: "🟡",
            Severity.LOW: "🔵",
            Severity.INFO: "⚪",
        }[self]
    
    @property
    def color(self) -> str:
        """Return a CSS color for the severity."""
        return {
            Severity.CRITICAL: "#dc3545",
            Severity.HIGH: "#fd7e14",
            Severity.MEDIUM: "#ffc107",
            Severity.LOW: "#17a2b8",
            Severity.INFO: "#6c757d",
        }[self]


class FindingCategory(Enum):
    """Categories of deprecation findings."""
    
    TERRAFORM = "terraform"
    KUBERNETES = "kubernetes"
    DOCKER = "docker"
    GITHUB_ACTIONS = "github-actions"
    SHELL = "shell"
    PYTHON = "python"
    GENERAL = "general"


@dataclass
class Finding:
    """
    Represents a single deprecation finding.
    
    Attributes:
        file_path: Path to the file containing the finding (relative to repo root)
        line_number: Line number where the issue was found (1-indexed)
        title: Short title describing the issue
        description: Detailed description of the deprecation
        severity: Severity level of the finding
        resource_type: Type of resource affected (e.g., "azurerm_kubernetes_cluster")
        resource_name: Name of the specific resource if identifiable
        current_version: Current version detected (if applicable)
        recommended_version: Recommended version to upgrade to
        suggested_fix: Suggested fix or remediation steps
        documentation_url: URL to relevant documentation
        category: Category of the finding
        rule_id: ID of the rule that triggered this finding
        matched_text: The actual text that matched the rule
    """
    
    file_path: str
    line_number: int
    title: str
    description: str
    severity: Severity
    resource_type: str = ""
    resource_name: str = ""
    current_version: Optional[str] = None
    recommended_version: Optional[str] = None
    suggested_fix: str = ""
    documentation_url: Optional[str] = None
    category: str = "general"
    rule_id: str = ""
    matched_text: str = ""
    
    def to_dict(self) -> Dict:
        """Convert finding to a dictionary for JSON serialization."""
        return {
            "file_path": self.file_path,
            "line_number": self.line_number,
            "title": self.title,
            "description": self.description,
            "severity": self.severity.value,
            "resource_type": self.resource_type,
            "resource_name": self.resource_name,
            "current_version": self.current_version,
            "recommended_version": self.recommended_version,
            "suggested_fix": self.suggested_fix,
            "documentation_url": self.documentation_url,
            "category": self.category,
            "rule_id": self.rule_id,
            "matched_text": self.matched_text,
        }
    
    @property
    def location(self) -> str:
        """Return a formatted location string."""
        return f"{self.file_path}:{self.line_number}"


@dataclass
class ScanResult:
    """
    Aggregated results from a repository scan.
    
    Attributes:
        repository_path: Path to the scanned repository
        findings: List of all findings discovered
        files_scanned: Total number of files scanned
        scan_duration_seconds: Time taken to complete the scan
        started_at: Timestamp when scan started
        completed_at: Timestamp when scan completed
        scanner_version: Version of the scanner used
    """
    
    repository_path: str
    findings: List[Finding] = field(default_factory=list)
    files_scanned: int = 0
    scan_duration_seconds: float = 0.0
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    scanner_version: str = "1.0.0"
    
    def get_summary(self) -> Dict:
        """
        Generate a summary of the scan results.
        
        Returns:
            Dictionary containing:
                - files_scanned: Number of files scanned
                - total_findings: Total number of findings
                - by_severity: Breakdown of findings by severity level
                - by_category: Breakdown of findings by category
                - scan_duration_seconds: Time taken for the scan
        """
        by_severity = {
            "critical": 0,
            "high": 0,
            "medium": 0,
            "low": 0,
            "info": 0,
        }
        
        by_category: Dict[str, int] = {}
        
        for finding in self.findings:
            by_severity[finding.severity.value] += 1
            category = finding.category
            by_category[category] = by_category.get(category, 0) + 1
        
        return {
            "files_scanned": self.files_scanned,
            "total_findings": len(self.findings),
            "by_severity": by_severity,
            "by_category": by_category,
            "scan_duration_seconds": round(self.scan_duration_seconds, 3),
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "scanner_version": self.scanner_version,
        }
    
    def get_findings_by_severity(self, severity: Severity) -> List[Finding]:
        """Get all findings with a specific severity level."""
        return [f for f in self.findings if f.severity == severity]
    
    def get_findings_by_category(self, category: str) -> List[Finding]:
        """Get all findings in a specific category."""
        return [f for f in self.findings if f.category == category]
    
    def get_critical_and_high(self) -> List[Finding]:
        """Get all critical and high severity findings."""
        return [f for f in self.findings if f.severity in (Severity.CRITICAL, Severity.HIGH)]
    
    def has_blocking_issues(self) -> bool:
        """Check if there are any critical or high severity findings."""
        return any(f.severity in (Severity.CRITICAL, Severity.HIGH) for f in self.findings)
    
    def to_dict(self) -> Dict:
        """Convert scan result to a dictionary for JSON serialization."""
        return {
            "repository_path": self.repository_path,
            "summary": self.get_summary(),
            "findings": [f.to_dict() for f in self.findings],
        }
