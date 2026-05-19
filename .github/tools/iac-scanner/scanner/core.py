"""
Core scanner implementation for IaC Deprecation Scanner.

This module provides the main DeprecationScanner class that orchestrates
the scanning of repositories for deprecated patterns.
"""

import logging
import os
import time
from datetime import datetime
from pathlib import Path
from typing import Generator, List, Optional, Set, Tuple

from scanner.findings import Finding, ScanResult, Severity
from scanner.rules import DEPRECATION_RULES, Rule, get_rules_for_file

# Configure logging
logger = logging.getLogger(__name__)


class DeprecationScanner:
    """
    Scanner for detecting deprecated patterns in Infrastructure as Code files.
    
    Supports scanning:
    - Terraform files (.tf, .tfvars)
    - Kubernetes YAML files (.yaml, .yml)
    - Dockerfiles
    - GitHub Actions workflows
    - Shell scripts (.sh)
    
    Attributes:
        offline_mode: If True, skip any network-dependent operations (reserved for future use)
        verbose: If True, enable verbose logging output
    """
    
    # Directories to skip during scanning
    SKIP_DIRECTORIES: Set[str] = {
        ".git",
        ".terraform",
        ".terragrunt-cache",
        "node_modules",
        ".venv",
        "venv",
        "env",
        "__pycache__",
        ".pytest_cache",
        ".mypy_cache",
        ".tox",
        "dist",
        "build",
        "target",
        ".eggs",
        "*.egg-info",
        ".cache",
        "vendor",
    }
    
    # File extensions to scan
    SCAN_EXTENSIONS: Set[str] = {
        ".tf",
        ".tfvars",
        ".yaml",
        ".yml",
        ".sh",
        ".bash",
        ".dockerfile",
        ".py",
    }
    
    # Special filenames to scan regardless of extension
    SCAN_FILENAMES: Set[str] = {
        "Dockerfile",
        "dockerfile",
        "Makefile",
        "makefile",
    }
    
    def __init__(self, offline_mode: bool = False, verbose: bool = False):
        """
        Initialize the scanner.
        
        Args:
            offline_mode: Skip network operations (reserved for future API checks)
            verbose: Enable verbose logging
        """
        self.offline_mode = offline_mode
        self.verbose = verbose
        
        # Configure logging level
        if verbose:
            logging.basicConfig(
                level=logging.DEBUG,
                format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            )
        else:
            logging.basicConfig(
                level=logging.INFO,
                format="%(levelname)s: %(message)s"
            )
        
        self._rules = DEPRECATION_RULES
        self._files_scanned = 0
        self._seen_findings: Set[Tuple[str, int, str]] = set()
    
    def scan_repository(self, repo_path: str) -> ScanResult:
        """
        Scan a repository for deprecated patterns.
        
        Args:
            repo_path: Path to the repository root directory
            
        Returns:
            ScanResult containing all findings and metadata
        """
        repo_path = os.path.abspath(repo_path)
        
        if not os.path.isdir(repo_path):
            raise ValueError(f"Repository path does not exist or is not a directory: {repo_path}")
        
        logger.info(f"Starting scan of repository: {repo_path}")
        
        started_at = datetime.now()
        start_time = time.time()
        
        self._files_scanned = 0
        self._seen_findings = set()
        findings: List[Finding] = []
        
        # Iterate through all relevant files
        for file_path in self._iter_files(repo_path):
            try:
                file_findings = self._scan_file(file_path, repo_path)
                findings.extend(file_findings)
                self._files_scanned += 1
            except Exception as e:
                logger.warning(f"Error scanning file {file_path}: {e}")
                continue
        
        completed_at = datetime.now()
        scan_duration = time.time() - start_time
        
        # Sort findings by severity (critical first), then by file path
        findings.sort(key=lambda f: (f.severity, f.file_path, f.line_number))
        
        logger.info(f"Scan complete. Scanned {self._files_scanned} files, found {len(findings)} issues.")
        
        return ScanResult(
            repository_path=repo_path,
            findings=findings,
            files_scanned=self._files_scanned,
            scan_duration_seconds=scan_duration,
            started_at=started_at,
            completed_at=completed_at,
        )
    
    def _iter_files(self, repo_path: str) -> Generator[Path, None, None]:
        """
        Iterate through all scannable files in the repository.
        
        Args:
            repo_path: Path to the repository root
            
        Yields:
            Path objects for each file to scan
        """
        repo_root = Path(repo_path)
        
        for root, dirs, files in os.walk(repo_root):
            root_path = Path(root)
            relative_root = root_path.relative_to(repo_root)
            
            # Skip .github/tools (where scanner lives) but allow .github/workflows
            if str(relative_root).replace("\\", "/").startswith(".github/tools"):
                dirs[:] = []
                continue
            
            # Filter out directories to skip (in-place modification)
            dirs[:] = [
                d for d in dirs
                if d not in self.SKIP_DIRECTORIES
                and not any(d.endswith(suffix) for suffix in [".egg-info"])
            ]
            
            for filename in files:
                file_path = root_path / filename
                
                # Check if file should be scanned
                if self._should_scan_file(filename):
                    yield file_path
    
    def _should_scan_file(self, filename: str) -> bool:
        """
        Determine if a file should be scanned based on its name.
        
        Args:
            filename: Name of the file
            
        Returns:
            True if the file should be scanned
        """
        # Check special filenames
        if filename in self.SCAN_FILENAMES:
            return True
        
        # Check Dockerfile patterns
        if filename.startswith("Dockerfile") or filename.lower().startswith("dockerfile"):
            return True
        
        # Check extensions
        _, ext = os.path.splitext(filename)
        return ext.lower() in self.SCAN_EXTENSIONS
    
    def _scan_file(self, file_path: Path, repo_root: str) -> List[Finding]:
        """
        Scan a single file for deprecated patterns.
        
        Args:
            file_path: Path to the file to scan
            repo_root: Root directory of the repository (for relative paths)
            
        Returns:
            List of findings from this file
        """
        findings: List[Finding] = []
        relative_path = str(file_path.relative_to(repo_root))
        filename = file_path.name
        
        logger.debug(f"Scanning: {relative_path}")
        
        # Read file content
        try:
            content = self._read_file_content(file_path)
        except Exception as e:
            logger.warning(f"Could not read file {relative_path}: {e}")
            return findings
        
        if not content:
            return findings
        
        # Get applicable rules for this file
        rules = get_rules_for_file(filename)
        
        # Apply each rule
        for rule in rules:
            rule_findings = self._apply_rule(rule, content, relative_path)
            findings.extend(rule_findings)
        
        return findings
    
    def _read_file_content(self, file_path: Path) -> str:
        """
        Read file content with encoding fallback.
        
        Args:
            file_path: Path to the file
            
        Returns:
            File content as string
        """
        # Try UTF-8 first, then fall back to latin-1 (which accepts any byte)
        encodings = ["utf-8", "utf-8-sig", "latin-1"]
        
        for encoding in encodings:
            try:
                with open(file_path, "r", encoding=encoding) as f:
                    return f.read()
            except UnicodeDecodeError:
                continue
            except Exception:
                raise
        
        # If all encodings fail, try binary and decode with errors ignored
        with open(file_path, "rb") as f:
            return f.read().decode("utf-8", errors="ignore")
    
    def _apply_rule(self, rule: Rule, content: str, file_path: str) -> List[Finding]:
        """
        Apply a single rule to file content.
        
        Args:
            rule: The rule to apply
            content: File content
            file_path: Relative path to the file
            
        Returns:
            List of findings from this rule
        """
        findings: List[Finding] = []
        
        # Find all matches
        matches = rule.matches(content)
        
        # Split content into lines for line number calculation
        lines = content.split("\n")
        
        for match in matches:
            # Calculate line number
            line_number = content[:match.start()].count("\n") + 1
            
            # Create a unique key to avoid duplicate findings
            finding_key = (file_path, line_number, rule.id)
            if finding_key in self._seen_findings:
                continue
            self._seen_findings.add(finding_key)
            
            # Get the matched text
            matched_text = match.group(0).strip()
            
            # Extract version if the rule has an extract function
            current_version = None
            if rule.extract_version:
                try:
                    current_version = rule.extract_version(match)
                except Exception:
                    pass
            
            if current_version is None:
                current_version = rule.current_version
            
            # Get the resource name from context if possible
            resource_name = self._extract_resource_name(lines, line_number - 1)
            
            finding = Finding(
                file_path=file_path,
                line_number=line_number,
                title=rule.title,
                description=rule.description,
                severity=rule.severity,
                resource_type=rule.resource_type,
                resource_name=resource_name,
                current_version=current_version,
                recommended_version=rule.recommended_version,
                suggested_fix=rule.suggested_fix,
                documentation_url=rule.documentation_url,
                category=rule.category,
                rule_id=rule.id,
                matched_text=matched_text[:100],  # Truncate long matches
            )
            
            findings.append(finding)
        
        return findings
    
    def _extract_resource_name(self, lines: List[str], line_index: int) -> str:
        """
        Try to extract a resource name from surrounding context.
        
        Args:
            lines: List of file lines
            line_index: Index of the current line
            
        Returns:
            Resource name if found, empty string otherwise
        """
        # Look for Terraform resource/data/module declarations
        for i in range(max(0, line_index - 5), line_index + 1):
            if i < len(lines):
                line = lines[i]
                
                # Match resource "type" "name"
                import re
                resource_match = re.match(
                    r'^\s*(?:resource|data|module)\s+["\']?(\w+)["\']?\s+["\']?(\w+)["\']?',
                    line
                )
                if resource_match:
                    return resource_match.group(2)
        
        return ""
    
    def get_rules_summary(self) -> dict:
        """
        Get a summary of all available rules.
        
        Returns:
            Dictionary with rule counts by category and severity
        """
        by_category: dict = {}
        by_severity: dict = {}
        
        for rule in self._rules:
            if not rule.enabled:
                continue
            
            # Count by category
            cat = rule.category
            by_category[cat] = by_category.get(cat, 0) + 1
            
            # Count by severity
            sev = rule.severity.value
            by_severity[sev] = by_severity.get(sev, 0) + 1
        
        return {
            "total_rules": len([r for r in self._rules if r.enabled]),
            "by_category": by_category,
            "by_severity": by_severity,
        }
