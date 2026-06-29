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
import re
import smtplib
import ssl
import subprocess
import sys
from email.message import EmailMessage
from getpass import getpass
from datetime import datetime
from typing import Any, Dict, List, Optional

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from scanner.core import DeprecationScanner
from scanner.report_generator import ReportGenerator
from scanner.findings import ScanResult
from scanner.future_intelligence import build_future_deprecation_intelligence


EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
DEFAULT_TEST_RECIPIENTS = [
    "lohit.dave@sas.com",
    "abhishek.kumar@sas.com",
    "Saptarshi.Rakshit@sas.com",
    "Gautam.Jayasankar@sas.com",
]


def _read_yes_no(prompt: str, default: bool = False) -> bool:
    """Read a yes/no answer from stdin."""

    suffix = "[Y/n]" if default else "[y/N]"
    raw = input(f"{prompt} {suffix}: ").strip().lower()
    if not raw:
        return default
    return raw in {"y", "yes"}


def _load_email_config() -> Dict[str, Any]:
    """Load SMTP config from environment variables."""

    host = os.getenv("IAC_SCAN_SMTP_HOST", "").strip()
    port_raw = os.getenv("IAC_SCAN_SMTP_PORT", "587").strip()
    username = os.getenv("IAC_SCAN_SMTP_USERNAME", "").strip()
    password = os.getenv("IAC_SCAN_SMTP_PASSWORD", "")
    from_email = os.getenv("IAC_SCAN_SMTP_FROM", username).strip()
    use_tls = os.getenv("IAC_SCAN_SMTP_USE_TLS", "true").strip().lower() in {"1", "true", "yes", "y"}
    use_ssl = os.getenv("IAC_SCAN_SMTP_USE_SSL", "false").strip().lower() in {"1", "true", "yes", "y"}

    try:
        port = int(port_raw)
    except ValueError:
        port = 587

    return {
        "host": host,
        "port": port,
        "username": username,
        "password": password,
        "from_email": from_email,
        "use_tls": use_tls,
        "use_ssl": use_ssl,
    }


def _parse_recipients(raw_value: str) -> List[str]:
    """Parse comma/semicolon separated recipients and filter invalid values."""

    normalized = raw_value.replace(";", ",")
    items = [item.strip() for item in normalized.split(",") if item.strip()]
    return [item for item in items if EMAIL_REGEX.match(item)]


def _send_email_report(
    smtp_config: Dict[str, Any],
    recipients: List[str],
    html_report_path: str,
    json_report_path: str,
    repo_path: str,
    total_findings: int,
) -> None:
    """Send report files to recipients through SMTP."""

    message = EmailMessage()
    message["Subject"] = f"IaC Code Compatibility Report - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    message["From"] = smtp_config["from_email"]
    message["To"] = ", ".join(recipients)
    message.set_content(
        "This is an IaC code compatibility report.\n\n"
        "What this report provides (short summary):\n"
        "- Deprecated or risky IaC patterns detected in Terraform and related automation.\n"
        "- Cloud provider deprecations, breaking changes, and adoption guidance relevant to current code compatibility.\n"
        "- Adoption guidance for supported features and versions.\n"
        "- Future risk signals to help plan proactive remediation.\n\n"
        "Why this matters:\n"
        "Use this report to review findings and take action to keep IaC code current, compatible, and up to date with cloud provider expectations.\n\n"
        f"Total findings: {total_findings}\n"
        f"Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        "Attachments:\n"
        "- iac-deprecation-report.html (readable report)\n"
        "- iac-deprecation-report.json (machine-readable report)\n"
    )

    with open(html_report_path, "rb") as html_file:
        message.add_attachment(
            html_file.read(),
            maintype="text",
            subtype="html",
            filename=os.path.basename(html_report_path),
        )

    with open(json_report_path, "rb") as json_file:
        message.add_attachment(
            json_file.read(),
            maintype="application",
            subtype="json",
            filename=os.path.basename(json_report_path),
        )

    context = ssl.create_default_context()
    if smtp_config["use_ssl"]:
        with smtplib.SMTP_SSL(smtp_config["host"], smtp_config["port"], context=context, timeout=30) as server:
            if smtp_config["username"]:
                server.login(smtp_config["username"], smtp_config["password"])
            server.send_message(message)
    else:
        with smtplib.SMTP(smtp_config["host"], smtp_config["port"], timeout=30) as server:
            if smtp_config["use_tls"]:
                server.starttls(context=context)
            if smtp_config["username"]:
                server.login(smtp_config["username"], smtp_config["password"])
            server.send_message(message)


def maybe_email_report(
    repo_path: str,
    html_report_path: str,
    json_report_path: str,
    total_findings: int,
) -> None:
    """Ask for confirmation and optionally send report by email."""

    print("\n" + "-" * 70)
    print("  ✉️  Optional Email Delivery")
    print("-" * 70)

    if not _read_yes_no("Do you want to send this report by email?", default=False):
        print("  • Email delivery skipped by user.")
        return

    recipient_kind_raw = input("Send to a group or person? [group/person] (default: person): ").strip().lower()
    recipient_kind = recipient_kind_raw if recipient_kind_raw in {"group", "person"} else "person"

    recipient_prompt = (
        "Enter group recipient emails (comma separated): "
        if recipient_kind == "group"
        else "Enter recipient email: "
    )
    entered_recipients = input(
        f"{recipient_prompt}(press Enter to use default test recipients: {', '.join(DEFAULT_TEST_RECIPIENTS)}): "
    ).strip()
    recipients = _parse_recipients(entered_recipients)
    if not recipients and not entered_recipients:
        recipients = DEFAULT_TEST_RECIPIENTS.copy()
    if not recipients:
        print("  • No valid recipient email address provided. Email not sent.")
        return

    print(f"  • Recipient type: {recipient_kind}")
    print(f"  • Recipients: {', '.join(recipients)}")
    if not _read_yes_no("Confirm sending the report email now?", default=False):
        print("  • Email delivery canceled by confirmation step.")
        return

    smtp_config = _load_email_config()
    required_keys = ["host", "from_email"]
    missing = [key for key in required_keys if not smtp_config.get(key)]
    if missing:
        print("  • SMTP configuration is incomplete.")
        print("    Required env vars: IAC_SCAN_SMTP_HOST, IAC_SCAN_SMTP_FROM")
        print("    Optional env vars: IAC_SCAN_SMTP_PORT, IAC_SCAN_SMTP_USERNAME, IAC_SCAN_SMTP_PASSWORD, IAC_SCAN_SMTP_USE_TLS, IAC_SCAN_SMTP_USE_SSL")
        return

    if smtp_config.get("username") and not smtp_config.get("password"):
        smtp_config["password"] = getpass("SMTP password: ")

    try:
        _send_email_report(
            smtp_config=smtp_config,
            recipients=recipients,
            html_report_path=html_report_path,
            json_report_path=json_report_path,
            repo_path=repo_path,
            total_findings=total_findings,
        )
        print("  • Report email sent successfully.")
    except Exception as exc:  # noqa: BLE001
        print(f"  • Failed to send report email: {exc}")


def detect_repo_kubernetes_default(repo_path: str) -> str:
    """Detect the default kubernetes_version from the repo's variables.tf."""

    variables_path = os.path.join(repo_path, "variables.tf")
    if not os.path.exists(variables_path):
        return "unknown"

    try:
        with open(variables_path, "r", encoding="utf-8") as handle:
            content = handle.read()
    except OSError:
        return "unknown"

    match = re.search(
        r'variable\s+"kubernetes_version"\s*\{.*?default\s*=\s*"([^"]+)"',
        content,
        re.DOTALL,
    )
    return match.group(1) if match else "unknown"


def get_kubernetes_136_impact_snapshot(repo_path: str) -> Dict[str, Any]:
    """Return a repo-specific AKS 1.36 impact assessment based on Azure docs."""

    current_default = detect_repo_kubernetes_default(repo_path)

    return {
        "sources": [
            {
                "title": "Supported Kubernetes Versions in Azure Kubernetes Service (AKS)",
                "url": "https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions",
                "last_updated": "2025-07-29",
            },
            {
                "title": "Upgrade Operating System (OS) Version in Azure Kubernetes Service (AKS) Clusters",
                "url": "https://learn.microsoft.com/en-us/azure/aks/upgrade-os-version",
                "last_updated": "2026-05-29",
            },
            {
                "title": "Node Images in Azure Kubernetes Service (AKS)",
                "url": "https://learn.microsoft.com/en-us/azure/aks/node-images",
                "last_updated": "2025-07-03",
            },
        ],
        "repo_current_default_kubernetes_version": current_default,
        "target_version": "1.36",
        "lifecycle": {
            "aks_ga": "2026-06",
            "end_of_life": "2027-06",
            "platform_support_until": "1.40 GA",
        },
        "repo_assessment": [
            {
                "severity": "medium",
                "area": "Version input wiring",
                "impact": "This repo passes kubernetes_version directly to both the control plane and node pools, with no validation that blocks 1.36. Terraform syntax is not the main risk.",
                "evidence": [
                    "main.tf wires var.kubernetes_version into module.aks and module.node_pools",
                    "modules/azure_aks/main.tf sets kubernetes_version and default_node_pool.orchestrator_version",
                    "modules/aks_node_pool/main.tf sets orchestrator_version on custom node pools",
                ],
            },
            {
                "severity": "high",
                "area": "Implicit Ubuntu OS changes",
                "impact": "The repo does not expose AKS os_sku on the cluster or node pools. Once users move to 1.35+ with the default Ubuntu OS SKU, AKS shifts the default Ubuntu image family to 24.04. That is an operational change outside the current Terraform surface.",
                "evidence": [
                    "variables.tf default kubernetes_version is currently 1.34",
                    "Azure docs state Ubuntu 24.04 becomes the default for os_sku Ubuntu in Kubernetes 1.35+",
                    "AKS resources in this repo set os_type for custom pools but do not set os_sku",
                ],
            },
            {
                "severity": "high",
                "area": "FIPS compatibility",
                "impact": "The repo supports fips_enabled on AKS and node pools, but Azure docs state Ubuntu 24.04 FIPS is not supported. Users enabling FIPS on Linux pools are the most likely to hit a 1.35/1.36 upgrade problem.",
                "evidence": [
                    "fips_enabled is wired into module.aks and module.node_pools",
                    "Azure docs state Ubuntu 24.04 node images do not support FIPS",
                ],
            },
            {
                "severity": "medium",
                "area": "Container runtime behavior",
                "impact": "Ubuntu 24.04 node images use containerd 2.0 by default. Workloads or operational tooling that depend on prior runtime behavior should be validated before adopting 1.36 on default Ubuntu nodes.",
                "evidence": [
                    "Azure docs state Ubuntu 24.04 on AKS uses containerd 2.0 by default",
                    "This repo leaves node OS SKU implicit for AKS node pools",
                ],
            },
            {
                "severity": "medium",
                "area": "Provider and module surface",
                "impact": "The manifest scan already flags AKS-related azurerm changes that become more relevant around 1.35/1.36, especially Ubuntu2404 OS SKU support and the container_log_max_lines rename. Even if current code does not reference those fields yet, future explicit OS control likely requires module/provider updates.",
                "evidence": [
                    "manifest scanner flags Ubuntu2404 support on azurerm_kubernetes_cluster and azurerm_kubernetes_cluster_node_pool",
                    "manifest scanner flags container_log_max_lines renamed to container_log_max_files",
                ],
            },
            {
                "severity": "low",
                "area": "Managed add-on churn",
                "impact": "AKS 1.36 changes managed component versions such as CoreDNS, KEDA, cloud-provider-node-manager, and cloud-provider-controller-manager. These are mostly AKS-managed, so the main code impact is validation rather than Terraform edits.",
                "evidence": [
                    "Azure docs list CoreDNS, KEDA, and cloud-provider component changes in the 1.36 breaking changes table",
                ],
            },
        ],
        "recommended_actions": [
            "Keep the repo default at 1.34 or move to 1.35 first for staged validation before setting 1.36 as the default.",
            "Add explicit AKS os_sku support to the AKS cluster and node pool modules if you need deterministic control over Ubuntu2204, Ubuntu2404, or AzureLinux3 behavior.",
            "If any deployment uses fips_enabled on AKS Linux pools, validate a non-Ubuntu strategy or explicit supported OS path before moving to 1.36.",
            "Test workload behavior on Ubuntu 24.04 and containerd 2.0 before changing the default kubernetes_version.",
            "Review the azurerm AKS resource changes already identified by the manifest scan before provider upgrades.",
        ],
    }


def build_kubernetes_136_impact_html(repo_path: str) -> str:
    """Build an HTML section for repo-specific AKS 1.36 readiness."""

    impact = get_kubernetes_136_impact_snapshot(repo_path)

    assessment_rows = "".join(
        [
            f"""
                <tr>
                    <td><strong>{item['severity'].upper()}</strong></td>
                    <td>{item['area']}</td>
                    <td>{item['impact']}</td>
                    <td><small>{'; '.join(item['evidence'])}</small></td>
                </tr>
            """
            for item in impact["repo_assessment"]
        ]
    )
    action_items = "".join([f"<li>{item}</li>" for item in impact["recommended_actions"]])
    source_links = "".join(
        [
            f'<li><a href="{item["url"]}" target="_blank">{item["title"]}</a> <span class="source-date">(updated {item["last_updated"]})</span></li>'
            for item in impact["sources"]
        ]
    )

    lifecycle = impact["lifecycle"]
    return f"""
        <section class="k8s-impact-section">
            <h2>⏭️ AKS Kubernetes 1.36 Impact on This Repo</h2>
            <p class="ubuntu-support-intro">
                Repo default Kubernetes version: <code>{impact['repo_current_default_kubernetes_version']}</code>. Target version reviewed: <code>{impact['target_version']}</code>.
            </p>

            <div class="future-summary ubuntu-notes">
                <h3>AKS 1.36 Lifecycle</h3>
                <ul>
                    <li>AKS GA: {lifecycle['aks_ga']}</li>
                    <li>AKS end of life: {lifecycle['end_of_life']}</li>
                    <li>Platform support: {lifecycle['platform_support_until']}</li>
                </ul>
            </div>

            <table class="findings-table">
                <thead>
                    <tr>
                        <th>Severity</th>
                        <th>Area</th>
                        <th>Impact on This Codebase</th>
                        <th>Evidence</th>
                    </tr>
                </thead>
                <tbody>
                    {assessment_rows}
                </tbody>
            </table>

            <div class="future-summary ubuntu-notes">
                <h3>Recommended Actions</h3>
                <ul>{action_items}</ul>
            </div>

            <div class="ubuntu-sources">
                <h3>Sources</h3>
                <ul>{source_links}</ul>
            </div>
        </section>
    """


def get_ubuntu_support_snapshot() -> Dict[str, Any]:
    """Return a curated AKS Ubuntu support snapshot sourced from Azure docs."""

    return {
        "sources": [
            {
                "title": "Node Images in Azure Kubernetes Service (AKS)",
                "url": "https://learn.microsoft.com/en-us/azure/aks/node-images",
                "last_updated": "2025-07-03",
            },
            {
                "title": "Upgrade Operating System (OS) Version in Azure Kubernetes Service (AKS) Clusters",
                "url": "https://learn.microsoft.com/en-us/azure/aks/upgrade-os-version",
                "last_updated": "2026-05-29",
            },
        ],
        "os_sku_support": [
            {
                "os_sku": "Ubuntu",
                "supported_kubernetes": "All supported AKS Kubernetes versions",
                "default_behavior": "Ubuntu 22.04 is the default for Kubernetes 1.25 to 1.34. Ubuntu 24.04 is the default for Kubernetes 1.35+.",
            },
            {
                "os_sku": "Ubuntu2204",
                "supported_kubernetes": "1.25 to 1.36",
                "default_behavior": "Versioned OS SKU for staying on or rolling back to Ubuntu 22.04.",
            },
            {
                "os_sku": "Ubuntu2404",
                "supported_kubernetes": "1.32 to 1.38",
                "default_behavior": "Versioned OS SKU for adopting Ubuntu 24.04 before Kubernetes 1.35 or for explicit pinning.",
            },
        ],
        "retirements": [
            {
                "version": "Ubuntu 20.04",
                "support_ends": "2027-03-17",
                "image_removal": "2027-03-17",
                "impact": "No AKS support or security updates. Existing node images are deleted and node pools can no longer scale.",
            },
            {
                "version": "Ubuntu 22.04",
                "support_ends": "2027-06-30",
                "image_removal": "2028-04-30",
                "impact": "After support ends, AKS stops producing new node images and security patches. After image removal, scaling and remediation operations fail.",
            },
        ],
        "node_image_support": [
            {
                "variant": "Ubuntu with containerd and Gen 1",
                "support": "Supported for Ubuntu node pools on VM sizes that only support Generation 1.",
                "limitations": "Used only when the VM size does not support Gen 2.",
            },
            {
                "variant": "Ubuntu with containerd and Gen 2",
                "support": "Default Ubuntu node image for VM sizes that support Generation 2.",
                "limitations": "Selected by default when a VM supports both Gen 1 and Gen 2.",
            },
            {
                "variant": "Ubuntu with containerd and FIPS",
                "support": "Supported for FIPS-enabled Ubuntu node pools on Gen 1 and Gen 2 where supported by AKS.",
                "limitations": "Not supported for Ubuntu 24.04+. Cannot be combined with Arm64 or CVM.",
            },
            {
                "variant": "Ubuntu with containerd and Arm64",
                "support": "Supported for Arm64 Ubuntu node pools.",
                "limitations": "Gen 2 only. Cannot be combined with FIPS, CVM, or Trusted Launch.",
            },
            {
                "variant": "Ubuntu with containerd and CVM",
                "support": "Supported for Confidential VM Ubuntu node pools on Ubuntu 20.04 and Ubuntu 24.04.",
                "limitations": "Not supported for Ubuntu 22.04. Gen 2 only. Cannot be combined with FIPS, Arm64, or Trusted Launch.",
            },
            {
                "variant": "Ubuntu with containerd and Trusted Launch",
                "support": "Supported for Trusted Launch Ubuntu node pools.",
                "limitations": "Gen 2 only. Cannot be combined with Arm64 or CVM.",
            },
        ],
        "migration_notes": [
            "For OS SKU Ubuntu, AKS automatically moves the default Ubuntu version to 24.04 when the cluster upgrades to Kubernetes 1.35 or later.",
            "Ubuntu 24.04 node images use containerd 2.0 by default, so workloads that depend on runtime behavior should be validated before migration.",
            "Ubuntu 24.04 does not support FIPS in AKS at this time.",
        ],
    }


def build_ubuntu_support_html() -> str:
    """Build an HTML section summarizing AKS Ubuntu support guidance."""

    support = get_ubuntu_support_snapshot()

    os_rows = "".join(
        [
            f"""
                <tr>
                    <td><code>{item['os_sku']}</code></td>
                    <td>{item['supported_kubernetes']}</td>
                    <td>{item['default_behavior']}</td>
                </tr>
            """
            for item in support["os_sku_support"]
        ]
    )

    retirement_rows = "".join(
        [
            f"""
                <tr>
                    <td><strong>{item['version']}</strong></td>
                    <td>{item['support_ends']}</td>
                    <td>{item['image_removal']}</td>
                    <td>{item['impact']}</td>
                </tr>
            """
            for item in support["retirements"]
        ]
    )

    node_rows = "".join(
        [
            f"""
                <tr>
                    <td>{item['variant']}</td>
                    <td>{item['support']}</td>
                    <td>{item['limitations']}</td>
                </tr>
            """
            for item in support["node_image_support"]
        ]
    )

    note_items = "".join([f"<li>{note}</li>" for note in support["migration_notes"]])
    source_links = "".join(
        [
            f'<li><a href="{item["url"]}" target="_blank">{item["title"]}</a> <span class="source-date">(updated {item["last_updated"]})</span></li>'
            for item in support["sources"]
        ]
    )

    return f"""
        <section class="ubuntu-support-section">
            <h2>🐧 AKS Ubuntu OS and Node Image Support</h2>
            <p class="ubuntu-support-intro">
                This section summarizes Ubuntu OS SKU support, retirement dates, and node image constraints from current Azure AKS documentation.
            </p>

            <h3>Ubuntu OS SKU Support</h3>
            <table class="findings-table">
                <thead>
                    <tr>
                        <th>OS SKU</th>
                        <th>Supported Kubernetes Versions</th>
                        <th>Default / Migration Behavior</th>
                    </tr>
                </thead>
                <tbody>
                    {os_rows}
                </tbody>
            </table>

            <h3>Ubuntu Retirement Milestones</h3>
            <table class="findings-table">
                <thead>
                    <tr>
                        <th>Version</th>
                        <th>Support Ends</th>
                        <th>Image Removal</th>
                        <th>Operational Impact</th>
                    </tr>
                </thead>
                <tbody>
                    {retirement_rows}
                </tbody>
            </table>

            <h3>Ubuntu Node Image Support</h3>
            <table class="findings-table">
                <thead>
                    <tr>
                        <th>Variant</th>
                        <th>Support</th>
                        <th>Limitations</th>
                    </tr>
                </thead>
                <tbody>
                    {node_rows}
                </tbody>
            </table>

            <div class="future-summary ubuntu-notes">
                <h3>Migration Notes</h3>
                <ul>{note_items}</ul>
            </div>

            <div class="ubuntu-sources">
                <h3>Sources</h3>
                <ul>{source_links}</ul>
            </div>
        </section>
    """


def get_platform_support_snapshot() -> Dict[str, Any]:
    """Return curated AKS Azure Linux and Windows support guidance from Azure docs."""

    return {
        "sources": [
            {
                "title": "Node Images in Azure Kubernetes Service (AKS)",
                "url": "https://learn.microsoft.com/en-us/azure/aks/node-images",
                "last_updated": "2025-07-03",
            },
            {
                "title": "Upgrade Operating System (OS) Version in Azure Kubernetes Service (AKS) Clusters",
                "url": "https://learn.microsoft.com/en-us/azure/aks/upgrade-os-version",
                "last_updated": "2026-05-29",
            },
        ],
        "release_cadence": [
            "Linux node images are released weekly and Windows node images are released monthly.",
            "New node images can take up to two weeks to roll out across all Azure regions.",
            "Azure recommends automatic node image upgrades and planned maintenance to keep nodes current.",
        ],
        "azure_linux_os_sku_support": [
            {
                "os_sku": "AzureLinux",
                "supported_kubernetes": "All supported AKS Kubernetes versions",
                "default_behavior": "Azure Linux 2.0 is default for Kubernetes 1.27 to 1.31. Azure Linux 3.0 is default for Kubernetes 1.32+.",
            },
            {
                "os_sku": "AzureLinux3",
                "supported_kubernetes": "1.28 to 1.36",
                "default_behavior": "Versioned OS SKU for explicit migration to Azure Linux 3.0 without a Kubernetes upgrade.",
            },
            {
                "os_sku": "AzureLinuxOSGuard",
                "supported_kubernetes": "1.32 and above",
                "default_behavior": "OS Guard images are upgraded through node image upgrades.",
            },
            {
                "os_sku": "Flatcar",
                "supported_kubernetes": "All supported AKS Kubernetes versions",
                "default_behavior": "Flatcar versions are delivered through node image upgrades.",
            },
            {
                "os_sku": "AzureContainerLinux",
                "supported_kubernetes": "1.34 and above",
                "default_behavior": "Azure Container Linux versions are delivered through node image upgrades.",
            },
        ],
        "windows_os_sku_support": [
            {
                "os_sku": "Windows2019",
                "supported_kubernetes": "1.14 to 1.32",
                "default_behavior": "Default Windows OS in Kubernetes 1.14 to 1.24.",
            },
            {
                "os_sku": "Windows2022",
                "supported_kubernetes": "1.23 to 1.34",
                "default_behavior": "Default Windows OS in Kubernetes 1.25 to 1.34.",
            },
        ],
        "retirements": [
            {
                "platform": "Azure Linux 2.0",
                "support_ends": "2025-11-30",
                "image_removal": "2026-03-31",
                "impact": "No new security updates after support ends, then node pools can no longer scale after image removal.",
            },
            {
                "platform": "Windows Server 2019",
                "support_ends": "2026-03-01",
                "image_removal": "2027-04-01",
                "impact": "Kubernetes 1.33+ cannot use Windows Server 2019. After image removal, scaling operations fail.",
            },
            {
                "platform": "Windows Server 2022",
                "support_ends": "2028-06-30",
                "image_removal": "2029-06-30",
                "impact": "Windows Server 2022 is not supported in Kubernetes 1.37+ and is fully removed later.",
            },
            {
                "platform": "Windows Annual Channel (Preview)",
                "support_ends": "2026-05-15",
                "image_removal": "2027-05-15",
                "impact": "No new node pools or security patches after support ends. Reimage and redeploy operations fail after removal.",
            },
        ],
        "node_image_support": [
            {
                "platform": "Azure Linux",
                "variant": "Gen 1 / Gen 2",
                "notes": "Standard node image for Azure Linux pools; Gen 2 is chosen when the VM supports both generations.",
            },
            {
                "platform": "Azure Linux",
                "variant": "FIPS / Arm64 / FIPS+Arm64 / Trusted Launch / Pod Sandboxing",
                "notes": "Feature-specific variants exist, but combinations are constrained. Trusted Launch, Pod Sandboxing, FIPS, and Arm64 cannot all be combined freely.",
            },
            {
                "platform": "Azure Linux OS Guard",
                "variant": "Gen 2 only",
                "notes": "OS Guard is preview-only and unavailable on Gen 1-only VM sizes.",
            },
            {
                "platform": "Windows LTSC",
                "variant": "Gen 1 / Gen 2",
                "notes": "Windows Server 2019 and 2022 use Gen 1 by default when a VM supports both Gen 1 and Gen 2. Windows Server 2025 selects Gen 2.",
            },
            {
                "platform": "Windows Annual Channel",
                "variant": "Gen 1 / Gen 2",
                "notes": "Preview channel only; use LTSC for long-term support.",
            },
        ],
        "migration_notes": [
            "For Azure Linux, Azure recommends the default OS SKU AzureLinux so clusters move to the latest GA Azure Linux version with Kubernetes upgrades.",
            "You can migrate Linux pools between supported OS SKUs with az aks nodepool update, but Windows OS SKUs are not supported by nodepool update and require adding node pools with the desired OS SKU.",
            "Windows guidance in Azure docs recommends Windows2022 for new Windows node pools.",
        ],
    }


def build_platform_support_html() -> str:
    """Build an HTML section for Azure Linux and Windows AKS support guidance."""

    support = get_platform_support_snapshot()

    cadence_items = "".join([f"<li>{item}</li>" for item in support["release_cadence"]])
    azure_linux_rows = "".join(
        [
            f"""
                <tr>
                    <td><code>{item['os_sku']}</code></td>
                    <td>{item['supported_kubernetes']}</td>
                    <td>{item['default_behavior']}</td>
                </tr>
            """
            for item in support["azure_linux_os_sku_support"]
        ]
    )
    windows_rows = "".join(
        [
            f"""
                <tr>
                    <td><code>{item['os_sku']}</code></td>
                    <td>{item['supported_kubernetes']}</td>
                    <td>{item['default_behavior']}</td>
                </tr>
            """
            for item in support["windows_os_sku_support"]
        ]
    )
    retirement_rows = "".join(
        [
            f"""
                <tr>
                    <td><strong>{item['platform']}</strong></td>
                    <td>{item['support_ends']}</td>
                    <td>{item['image_removal']}</td>
                    <td>{item['impact']}</td>
                </tr>
            """
            for item in support["retirements"]
        ]
    )
    node_rows = "".join(
        [
            f"""
                <tr>
                    <td>{item['platform']}</td>
                    <td>{item['variant']}</td>
                    <td>{item['notes']}</td>
                </tr>
            """
            for item in support["node_image_support"]
        ]
    )
    note_items = "".join([f"<li>{note}</li>" for note in support["migration_notes"]])
    source_links = "".join(
        [
            f'<li><a href="{item["url"]}" target="_blank">{item["title"]}</a> <span class="source-date">(updated {item["last_updated"]})</span></li>'
            for item in support["sources"]
        ]
    )

    return f"""
        <section class="platform-support-section">
            <h2>🖥️ AKS Azure Linux and Windows Support</h2>
            <p class="ubuntu-support-intro">
                This section summarizes Azure Linux and Windows OS SKU support, retirements, and node image constraints from current Azure AKS documentation.
            </p>

            <div class="future-summary ubuntu-notes">
                <h3>Node Image Release Cadence</h3>
                <ul>{cadence_items}</ul>
            </div>

            <h3>Azure Linux OS SKU Support</h3>
            <table class="findings-table">
                <thead>
                    <tr>
                        <th>OS SKU</th>
                        <th>Supported Kubernetes Versions</th>
                        <th>Default / Migration Behavior</th>
                    </tr>
                </thead>
                <tbody>
                    {azure_linux_rows}
                </tbody>
            </table>

            <h3>Windows OS SKU Support</h3>
            <table class="findings-table">
                <thead>
                    <tr>
                        <th>OS SKU</th>
                        <th>Supported Kubernetes Versions</th>
                        <th>Default / Migration Behavior</th>
                    </tr>
                </thead>
                <tbody>
                    {windows_rows}
                </tbody>
            </table>

            <h3>Platform Retirement Milestones</h3>
            <table class="findings-table">
                <thead>
                    <tr>
                        <th>Platform</th>
                        <th>Support Ends</th>
                        <th>Image Removal</th>
                        <th>Operational Impact</th>
                    </tr>
                </thead>
                <tbody>
                    {retirement_rows}
                </tbody>
            </table>

            <h3>Azure Linux and Windows Node Image Notes</h3>
            <table class="findings-table">
                <thead>
                    <tr>
                        <th>Platform</th>
                        <th>Variant</th>
                        <th>Notes</th>
                    </tr>
                </thead>
                <tbody>
                    {node_rows}
                </tbody>
            </table>

            <div class="future-summary ubuntu-notes">
                <h3>Migration Notes</h3>
                <ul>{note_items}</ul>
            </div>

            <div class="ubuntu-sources">
                <h3>Sources</h3>
                <ul>{source_links}</ul>
            </div>
        </section>
    """


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

    ubuntu_support_html = build_ubuntu_support_html()
    platform_support_html = build_platform_support_html()
    k8s_136_impact_html = build_kubernetes_136_impact_html(repo_path)
    
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

        .ubuntu-support-section {{
            background: var(--card-bg);
            border-radius: 8px;
            padding: 25px;
            margin-top: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}

        .platform-support-section {{
            background: var(--card-bg);
            border-radius: 8px;
            padding: 25px;
            margin-top: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}

        .ubuntu-support-section h2,
        .ubuntu-support-section h3,
        .platform-support-section h2,
        .platform-support-section h3 {{
            margin-bottom: 12px;
        }}

        .ubuntu-support-section h2,
        .platform-support-section h2 {{
            padding-bottom: 10px;
            border-bottom: 2px solid var(--border-color);
        }}

        .ubuntu-support-section h3,
        .platform-support-section h3 {{
            margin-top: 18px;
        }}

        .ubuntu-support-intro,
        .ubuntu-sources {{
            color: #495057;
        }}

        .ubuntu-notes,
        .ubuntu-sources {{
            margin-top: 16px;
        }}

        .ubuntu-sources ul {{
            margin-left: 20px;
        }}

        .source-date {{
            color: #6c757d;
            font-size: 0.85rem;
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

        {ubuntu_support_html}

        {platform_support_html}

        {k8s_136_impact_html}
        
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
        "aks_ubuntu_support": get_ubuntu_support_snapshot(),
        "aks_platform_support": get_platform_support_snapshot(),
        "aks_kubernetes_136_impact": get_kubernetes_136_impact_snapshot(target_repo),
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

    maybe_email_report(
        repo_path=target_repo,
        html_report_path=html_output,
        json_report_path=json_output,
        total_findings=summary["total_findings"],
    )
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
