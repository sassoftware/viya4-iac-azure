"""
Version data catalog for IaC Deprecation Scanner.

Contains known deprecated versions, recommended upgrades, and end-of-life dates
for common infrastructure components.
"""

from dataclasses import dataclass
from datetime import date
from typing import Dict, List, Optional


@dataclass
class VersionInfo:
    """Information about a specific version."""
    
    version: str
    status: str  # "current", "deprecated", "eol", "security-only"
    eol_date: Optional[date] = None
    recommended_upgrade: Optional[str] = None
    notes: str = ""


# =============================================================================
# Terraform Provider Versions
# =============================================================================

AZURERM_VERSIONS: Dict[str, VersionInfo] = {
    # Old major versions - EOL
    "1.x": VersionInfo(
        version="1.x",
        status="eol",
        eol_date=date(2021, 2, 28),
        recommended_upgrade="4.x",
        notes="Major version 1.x reached EOL. Contains breaking changes from 4.x.",
    ),
    "2.x": VersionInfo(
        version="2.x",
        status="eol",
        eol_date=date(2023, 9, 30),
        recommended_upgrade="4.x",
        notes="Major version 2.x is no longer maintained.",
    ),
    "3.x": VersionInfo(
        version="3.x",
        status="deprecated",
        eol_date=date(2024, 11, 30),
        recommended_upgrade="4.x",
        notes="Major version 3.x will reach EOL soon. Plan migration to 4.x.",
    ),
    # Current
    "4.x": VersionInfo(
        version="4.x",
        status="current",
        recommended_upgrade=None,
        notes="Current major version. Keep updated to latest 4.x release.",
    ),
}

# Minimum recommended azurerm version
AZURERM_MIN_RECOMMENDED = "4.0.0"
AZURERM_LATEST_KNOWN = "4.73.0"

# =============================================================================
# Terraform Core Versions
# =============================================================================

TERRAFORM_VERSIONS: Dict[str, VersionInfo] = {
    "0.11": VersionInfo(
        version="0.11",
        status="eol",
        eol_date=date(2021, 8, 10),
        recommended_upgrade="1.9",
        notes="Terraform 0.11 is end of life. Major syntax changes required.",
    ),
    "0.12": VersionInfo(
        version="0.12",
        status="eol",
        eol_date=date(2022, 5, 3),
        recommended_upgrade="1.9",
        notes="Terraform 0.12 is end of life.",
    ),
    "0.13": VersionInfo(
        version="0.13",
        status="eol",
        eol_date=date(2022, 9, 7),
        recommended_upgrade="1.9",
        notes="Terraform 0.13 is end of life.",
    ),
    "0.14": VersionInfo(
        version="0.14",
        status="eol",
        eol_date=date(2023, 2, 8),
        recommended_upgrade="1.9",
        notes="Terraform 0.14 is end of life.",
    ),
    "0.15": VersionInfo(
        version="0.15",
        status="eol",
        eol_date=date(2023, 4, 12),
        recommended_upgrade="1.9",
        notes="Terraform 0.15 is end of life.",
    ),
    "1.0": VersionInfo(
        version="1.0",
        status="deprecated",
        eol_date=date(2024, 6, 26),
        recommended_upgrade="1.9",
        notes="Terraform 1.0 is deprecated. Upgrade to 1.9+.",
    ),
    "1.1": VersionInfo(
        version="1.1",
        status="deprecated",
        eol_date=date(2024, 9, 18),
        recommended_upgrade="1.9",
        notes="Terraform 1.1 is deprecated.",
    ),
    "1.2": VersionInfo(
        version="1.2",
        status="deprecated",
        eol_date=date(2024, 12, 11),
        recommended_upgrade="1.9",
        notes="Terraform 1.2 is deprecated.",
    ),
    "1.3": VersionInfo(
        version="1.3",
        status="security-only",
        recommended_upgrade="1.9",
        notes="Terraform 1.3 receives security updates only.",
    ),
    "1.4": VersionInfo(
        version="1.4",
        status="security-only",
        recommended_upgrade="1.9",
        notes="Terraform 1.4 receives security updates only.",
    ),
    "1.5": VersionInfo(
        version="1.5",
        status="current",
        recommended_upgrade="1.9",
        notes="Consider upgrading to latest 1.9 for new features.",
    ),
    "1.6": VersionInfo(
        version="1.6",
        status="current",
        recommended_upgrade=None,
        notes="Current version.",
    ),
    "1.7": VersionInfo(
        version="1.7",
        status="current",
        recommended_upgrade=None,
        notes="Current version.",
    ),
    "1.8": VersionInfo(
        version="1.8",
        status="current",
        recommended_upgrade=None,
        notes="Current version.",
    ),
    "1.9": VersionInfo(
        version="1.9",
        status="current",
        recommended_upgrade=None,
        notes="Latest stable version.",
    ),
}

TERRAFORM_MIN_RECOMMENDED = "1.5.0"

# =============================================================================
# Kubernetes API Versions
# =============================================================================

# Deprecated Kubernetes API versions and their replacements
K8S_DEPRECATED_API_VERSIONS: Dict[str, Dict[str, str]] = {
    # Extensions API group - removed in 1.22
    "extensions/v1beta1": {
        "Deployment": "apps/v1",
        "DaemonSet": "apps/v1",
        "ReplicaSet": "apps/v1",
        "Ingress": "networking.k8s.io/v1",
        "NetworkPolicy": "networking.k8s.io/v1",
        "PodSecurityPolicy": "policy/v1beta1",  # Also deprecated
    },
    # Apps v1beta1 - removed in 1.16
    "apps/v1beta1": {
        "Deployment": "apps/v1",
        "StatefulSet": "apps/v1",
    },
    # Apps v1beta2 - removed in 1.16
    "apps/v1beta2": {
        "Deployment": "apps/v1",
        "DaemonSet": "apps/v1",
        "ReplicaSet": "apps/v1",
        "StatefulSet": "apps/v1",
    },
    # Networking v1beta1 - removed in 1.22
    "networking.k8s.io/v1beta1": {
        "Ingress": "networking.k8s.io/v1",
        "IngressClass": "networking.k8s.io/v1",
    },
    # Batch v1beta1 - removed in 1.25
    "batch/v1beta1": {
        "CronJob": "batch/v1",
    },
    # Policy v1beta1 - removed in 1.25
    "policy/v1beta1": {
        "PodDisruptionBudget": "policy/v1",
        "PodSecurityPolicy": "REMOVED",  # PSP removed entirely
    },
    # Autoscaling v2beta1 - deprecated in 1.23
    "autoscaling/v2beta1": {
        "HorizontalPodAutoscaler": "autoscaling/v2",
    },
    # Autoscaling v2beta2 - deprecated in 1.23
    "autoscaling/v2beta2": {
        "HorizontalPodAutoscaler": "autoscaling/v2",
    },
    # CertificateSigningRequest v1beta1 - removed in 1.22
    "certificates.k8s.io/v1beta1": {
        "CertificateSigningRequest": "certificates.k8s.io/v1",
    },
    # Storage v1beta1 - deprecated
    "storage.k8s.io/v1beta1": {
        "CSIDriver": "storage.k8s.io/v1",
        "CSINode": "storage.k8s.io/v1",
        "StorageClass": "storage.k8s.io/v1",
        "VolumeAttachment": "storage.k8s.io/v1",
    },
    # Admissionregistration v1beta1 - removed in 1.22
    "admissionregistration.k8s.io/v1beta1": {
        "MutatingWebhookConfiguration": "admissionregistration.k8s.io/v1",
        "ValidatingWebhookConfiguration": "admissionregistration.k8s.io/v1",
    },
    # RBAC v1beta1 - removed in 1.22
    "rbac.authorization.k8s.io/v1beta1": {
        "ClusterRole": "rbac.authorization.k8s.io/v1",
        "ClusterRoleBinding": "rbac.authorization.k8s.io/v1",
        "Role": "rbac.authorization.k8s.io/v1",
        "RoleBinding": "rbac.authorization.k8s.io/v1",
    },
    # Scheduling v1beta1 - removed in 1.22
    "scheduling.k8s.io/v1beta1": {
        "PriorityClass": "scheduling.k8s.io/v1",
    },
    # Coordination v1beta1 - removed in 1.22
    "coordination.k8s.io/v1beta1": {
        "Lease": "coordination.k8s.io/v1",
    },
    # Discovery v1beta1 - deprecated in 1.21
    "discovery.k8s.io/v1beta1": {
        "EndpointSlice": "discovery.k8s.io/v1",
    },
    # FlowControl v1beta1 - deprecated in 1.26
    "flowcontrol.apiserver.k8s.io/v1beta1": {
        "FlowSchema": "flowcontrol.apiserver.k8s.io/v1",
        "PriorityLevelConfiguration": "flowcontrol.apiserver.k8s.io/v1",
    },
    # FlowControl v1beta2 - deprecated in 1.26
    "flowcontrol.apiserver.k8s.io/v1beta2": {
        "FlowSchema": "flowcontrol.apiserver.k8s.io/v1",
        "PriorityLevelConfiguration": "flowcontrol.apiserver.k8s.io/v1",
    },
}

# =============================================================================
# Docker Base Images
# =============================================================================

DEPRECATED_DOCKER_IMAGES: Dict[str, Dict[str, str]] = {
    # CentOS - EOL
    "centos:6": {
        "status": "eol",
        "eol_date": "2020-11-30",
        "recommended": "rockylinux:9 or almalinux:9",
        "notes": "CentOS 6 reached EOL. Migrate to Rocky Linux or AlmaLinux.",
    },
    "centos:7": {
        "status": "eol",
        "eol_date": "2024-06-30",
        "recommended": "rockylinux:9 or almalinux:9",
        "notes": "CentOS 7 reached EOL. Migrate to Rocky Linux or AlmaLinux.",
    },
    "centos:8": {
        "status": "eol",
        "eol_date": "2021-12-31",
        "recommended": "rockylinux:9 or almalinux:9",
        "notes": "CentOS 8 reached early EOL. Use Rocky Linux or AlmaLinux.",
    },
    # Ubuntu LTS - old versions
    "ubuntu:14.04": {
        "status": "eol",
        "eol_date": "2024-04-25",
        "recommended": "ubuntu:24.04",
        "notes": "Ubuntu 14.04 ESM ended. Upgrade to Ubuntu 24.04 LTS.",
    },
    "ubuntu:16.04": {
        "status": "eol",
        "eol_date": "2026-04-02",
        "recommended": "ubuntu:24.04",
        "notes": "Ubuntu 16.04 ESM ending soon. Plan upgrade to 24.04 LTS.",
    },
    "ubuntu:18.04": {
        "status": "deprecated",
        "eol_date": "2028-04-01",
        "recommended": "ubuntu:24.04",
        "notes": "Ubuntu 18.04 is in ESM. Consider upgrading to 24.04 LTS.",
    },
    "ubuntu:20.04": {
        "status": "current",
        "eol_date": "2030-04-02",
        "recommended": "ubuntu:24.04",
        "notes": "Ubuntu 20.04 LTS is still supported but consider 24.04.",
    },
    # Node.js
    "node:10": {
        "status": "eol",
        "eol_date": "2021-04-30",
        "recommended": "node:20 or node:22",
        "notes": "Node.js 10 is EOL. Upgrade to Node.js 20 LTS or 22 LTS.",
    },
    "node:12": {
        "status": "eol",
        "eol_date": "2022-04-30",
        "recommended": "node:20 or node:22",
        "notes": "Node.js 12 is EOL. Upgrade to Node.js 20 LTS or 22 LTS.",
    },
    "node:14": {
        "status": "eol",
        "eol_date": "2023-04-30",
        "recommended": "node:20 or node:22",
        "notes": "Node.js 14 is EOL. Upgrade to Node.js 20 LTS or 22 LTS.",
    },
    "node:16": {
        "status": "eol",
        "eol_date": "2024-04-30",
        "recommended": "node:20 or node:22",
        "notes": "Node.js 16 is EOL. Upgrade to Node.js 20 LTS or 22 LTS.",
    },
    "node:18": {
        "status": "deprecated",
        "eol_date": "2025-04-30",
        "recommended": "node:20 or node:22",
        "notes": "Node.js 18 approaching EOL. Plan upgrade to 20 or 22 LTS.",
    },
    # Python
    "python:2": {
        "status": "eol",
        "eol_date": "2020-01-01",
        "recommended": "python:3.12",
        "notes": "Python 2 is EOL. Migrate to Python 3.",
    },
    "python:2.7": {
        "status": "eol",
        "eol_date": "2020-01-01",
        "recommended": "python:3.12",
        "notes": "Python 2.7 is EOL. Migrate to Python 3.",
    },
    "python:3.5": {
        "status": "eol",
        "eol_date": "2020-09-13",
        "recommended": "python:3.12",
        "notes": "Python 3.5 is EOL. Upgrade to Python 3.12.",
    },
    "python:3.6": {
        "status": "eol",
        "eol_date": "2021-12-23",
        "recommended": "python:3.12",
        "notes": "Python 3.6 is EOL. Upgrade to Python 3.12.",
    },
    "python:3.7": {
        "status": "eol",
        "eol_date": "2023-06-27",
        "recommended": "python:3.12",
        "notes": "Python 3.7 is EOL. Upgrade to Python 3.12.",
    },
    "python:3.8": {
        "status": "security-only",
        "eol_date": "2024-10-14",
        "recommended": "python:3.12",
        "notes": "Python 3.8 in security-only mode. Plan upgrade.",
    },
    # Alpine old versions
    "alpine:3.12": {
        "status": "eol",
        "eol_date": "2022-05-01",
        "recommended": "alpine:3.20",
        "notes": "Alpine 3.12 is EOL. Upgrade to latest Alpine.",
    },
    "alpine:3.13": {
        "status": "eol",
        "eol_date": "2022-11-01",
        "recommended": "alpine:3.20",
        "notes": "Alpine 3.13 is EOL. Upgrade to latest Alpine.",
    },
    "alpine:3.14": {
        "status": "eol",
        "eol_date": "2023-05-01",
        "recommended": "alpine:3.20",
        "notes": "Alpine 3.14 is EOL. Upgrade to latest Alpine.",
    },
    "alpine:3.15": {
        "status": "eol",
        "eol_date": "2023-11-01",
        "recommended": "alpine:3.20",
        "notes": "Alpine 3.15 is EOL. Upgrade to latest Alpine.",
    },
    # Debian old versions
    "debian:stretch": {
        "status": "eol",
        "eol_date": "2022-07-01",
        "recommended": "debian:bookworm",
        "notes": "Debian Stretch (9) is EOL. Upgrade to Bookworm (12).",
    },
    "debian:buster": {
        "status": "eol",
        "eol_date": "2024-06-30",
        "recommended": "debian:bookworm",
        "notes": "Debian Buster (10) LTS ended. Upgrade to Bookworm (12).",
    },
    "debian:9": {
        "status": "eol",
        "eol_date": "2022-07-01",
        "recommended": "debian:12",
        "notes": "Debian 9 is EOL. Upgrade to Debian 12.",
    },
    "debian:10": {
        "status": "eol",
        "eol_date": "2024-06-30",
        "recommended": "debian:12",
        "notes": "Debian 10 LTS ended. Upgrade to Debian 12.",
    },
}

# =============================================================================
# GitHub Actions
# =============================================================================

DEPRECATED_GITHUB_ACTIONS: Dict[str, Dict[str, str]] = {
    # Checkout
    "actions/checkout@v1": {
        "recommended": "actions/checkout@v4",
        "notes": "v1 uses deprecated Node.js 12 runtime.",
    },
    "actions/checkout@v2": {
        "recommended": "actions/checkout@v4",
        "notes": "v2 uses deprecated Node.js 12 runtime.",
    },
    "actions/checkout@v3": {
        "recommended": "actions/checkout@v4",
        "notes": "v3 uses Node.js 16 which is EOL. Upgrade to v4.",
    },
    # Setup Python
    "actions/setup-python@v1": {
        "recommended": "actions/setup-python@v5",
        "notes": "v1 uses deprecated Node.js runtime.",
    },
    "actions/setup-python@v2": {
        "recommended": "actions/setup-python@v5",
        "notes": "v2 uses deprecated Node.js runtime.",
    },
    "actions/setup-python@v3": {
        "recommended": "actions/setup-python@v5",
        "notes": "v3 uses deprecated Node.js runtime.",
    },
    "actions/setup-python@v4": {
        "recommended": "actions/setup-python@v5",
        "notes": "v4 uses Node.js 16. Upgrade to v5.",
    },
    # Setup Node
    "actions/setup-node@v1": {
        "recommended": "actions/setup-node@v4",
        "notes": "v1 uses deprecated Node.js runtime.",
    },
    "actions/setup-node@v2": {
        "recommended": "actions/setup-node@v4",
        "notes": "v2 uses deprecated Node.js runtime.",
    },
    "actions/setup-node@v3": {
        "recommended": "actions/setup-node@v4",
        "notes": "v3 uses Node.js 16. Upgrade to v4.",
    },
    # Cache
    "actions/cache@v1": {
        "recommended": "actions/cache@v4",
        "notes": "v1 uses deprecated Node.js runtime.",
    },
    "actions/cache@v2": {
        "recommended": "actions/cache@v4",
        "notes": "v2 uses deprecated Node.js runtime.",
    },
    "actions/cache@v3": {
        "recommended": "actions/cache@v4",
        "notes": "v3 uses Node.js 16. Upgrade to v4.",
    },
    # Upload/Download Artifact
    "actions/upload-artifact@v1": {
        "recommended": "actions/upload-artifact@v4",
        "notes": "v1 uses deprecated Node.js runtime.",
    },
    "actions/upload-artifact@v2": {
        "recommended": "actions/upload-artifact@v4",
        "notes": "v2 uses deprecated Node.js runtime.",
    },
    "actions/upload-artifact@v3": {
        "recommended": "actions/upload-artifact@v4",
        "notes": "v3 uses Node.js 16. Upgrade to v4.",
    },
    "actions/download-artifact@v1": {
        "recommended": "actions/download-artifact@v4",
        "notes": "v1 uses deprecated Node.js runtime.",
    },
    "actions/download-artifact@v2": {
        "recommended": "actions/download-artifact@v4",
        "notes": "v2 uses deprecated Node.js runtime.",
    },
    "actions/download-artifact@v3": {
        "recommended": "actions/download-artifact@v4",
        "notes": "v3 uses Node.js 16. Upgrade to v4.",
    },
    # Setup Go
    "actions/setup-go@v1": {
        "recommended": "actions/setup-go@v5",
        "notes": "v1 uses deprecated Node.js runtime.",
    },
    "actions/setup-go@v2": {
        "recommended": "actions/setup-go@v5",
        "notes": "v2 uses deprecated Node.js runtime.",
    },
    "actions/setup-go@v3": {
        "recommended": "actions/setup-go@v5",
        "notes": "v3 uses deprecated Node.js runtime.",
    },
    "actions/setup-go@v4": {
        "recommended": "actions/setup-go@v5",
        "notes": "v4 uses Node.js 16. Upgrade to v5.",
    },
    # Setup Java
    "actions/setup-java@v1": {
        "recommended": "actions/setup-java@v4",
        "notes": "v1 uses deprecated Node.js runtime.",
    },
    "actions/setup-java@v2": {
        "recommended": "actions/setup-java@v4",
        "notes": "v2 uses deprecated Node.js runtime.",
    },
    "actions/setup-java@v3": {
        "recommended": "actions/setup-java@v4",
        "notes": "v3 uses Node.js 16. Upgrade to v4.",
    },
    # Azure Login
    "azure/login@v1": {
        "recommended": "azure/login@v2",
        "notes": "v1 uses deprecated authentication methods.",
    },
    # HashiCorp Setup Terraform
    "hashicorp/setup-terraform@v1": {
        "recommended": "hashicorp/setup-terraform@v3",
        "notes": "v1 uses deprecated Node.js runtime.",
    },
    "hashicorp/setup-terraform@v2": {
        "recommended": "hashicorp/setup-terraform@v3",
        "notes": "v2 uses Node.js 16. Upgrade to v3.",
    },
}

# Node.js runtime deprecations in GitHub Actions
GITHUB_ACTIONS_NODE_DEPRECATIONS = {
    "node12": {
        "status": "removed",
        "message": "Node.js 12 actions are no longer supported by GitHub.",
        "recommended": "node20",
    },
    "node16": {
        "status": "deprecated",
        "message": "Node.js 16 actions will stop working on 2024-06-30.",
        "recommended": "node20",
    },
}
