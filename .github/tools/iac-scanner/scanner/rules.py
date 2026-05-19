"""
Deprecation rules catalog for IaC Scanner.

This module defines all the rules used to detect deprecated patterns
in Terraform, Kubernetes, Docker, GitHub Actions, and shell files.
"""

import re
from dataclasses import dataclass, field
from typing import Callable, List, Optional, Pattern

from scanner.findings import Severity


@dataclass
class Rule:
    """
    A deprecation detection rule.
    
    Attributes:
        id: Unique identifier for the rule
        category: Category (terraform, kubernetes, docker, github-actions, shell)
        title: Short title for findings
        description: Detailed description of the deprecation
        severity: Severity level of matches
        pattern: Compiled regex pattern to match
        file_patterns: List of file glob patterns this rule applies to
        resource_type: Type of resource this rule detects
        current_version: The deprecated version being detected (for context)
        recommended_version: Recommended version to upgrade to
        suggested_fix: How to fix the issue
        documentation_url: URL to documentation
        enabled: Whether the rule is enabled
        extract_version: Optional function to extract version from match
    """
    
    id: str
    category: str
    title: str
    description: str
    severity: Severity
    pattern: Pattern
    file_patterns: List[str] = field(default_factory=list)
    resource_type: str = ""
    current_version: Optional[str] = None
    recommended_version: Optional[str] = None
    suggested_fix: str = ""
    documentation_url: Optional[str] = None
    enabled: bool = True
    extract_version: Optional[Callable[[re.Match], Optional[str]]] = None
    
    def matches(self, content: str) -> List[re.Match]:
        """Find all matches in the content."""
        return list(self.pattern.finditer(content))


def _build_rules() -> List[Rule]:
    """Build and return all deprecation rules."""
    rules: List[Rule] = []
    
    # =========================================================================
    # TERRAFORM RULES
    # =========================================================================
    
    # Old azurerm provider major versions
    rules.append(Rule(
        id="TF001",
        category="terraform",
        title="Deprecated azurerm provider version 1.x",
        description="azurerm provider version 1.x is end-of-life and no longer maintained.",
        severity=Severity.CRITICAL,
        pattern=re.compile(
            r'version\s*=\s*["\']~?\s*[>=<]*\s*1\.\d+',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="azurerm_provider",
        recommended_version="~> 4.0",
        suggested_fix="Update provider version constraint to ~> 4.0 and follow migration guide.",
        documentation_url="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide",
    ))
    
    rules.append(Rule(
        id="TF002",
        category="terraform",
        title="Deprecated azurerm provider version 2.x",
        description="azurerm provider version 2.x is deprecated and will not receive updates.",
        severity=Severity.HIGH,
        pattern=re.compile(
            r'version\s*=\s*["\']~?\s*[>=<]*\s*2\.\d+',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="azurerm_provider",
        recommended_version="~> 4.0",
        suggested_fix="Update provider version constraint to ~> 4.0 and follow migration guide.",
        documentation_url="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide",
    ))
    
    rules.append(Rule(
        id="TF003",
        category="terraform",
        title="Deprecated azurerm provider version 3.x",
        description="azurerm provider version 3.x is deprecated. Migration to 4.x is recommended.",
        severity=Severity.MEDIUM,
        pattern=re.compile(
            r'version\s*=\s*["\']~?\s*[>=<]*\s*3\.\d+',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="azurerm_provider",
        recommended_version="~> 4.0",
        suggested_fix="Plan migration to azurerm 4.x. Review breaking changes in upgrade guide.",
        documentation_url="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide",
    ))
    
    # Old Terraform required_version
    rules.append(Rule(
        id="TF004",
        category="terraform",
        title="Deprecated Terraform version 0.x",
        description="Terraform 0.x versions are end-of-life and have known security issues.",
        severity=Severity.CRITICAL,
        pattern=re.compile(
            r'required_version\s*=\s*["\'][>=<~\s]*0\.\d+',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="terraform_version",
        recommended_version=">= 1.5.0",
        suggested_fix="Upgrade to Terraform 1.5+ and update required_version constraint.",
        documentation_url="https://developer.hashicorp.com/terraform/language/settings#specifying-a-required-terraform-version",
    ))
    
    rules.append(Rule(
        id="TF005",
        category="terraform",
        title="Deprecated Terraform version 1.0-1.2",
        description="Terraform versions 1.0-1.2 are deprecated and no longer receive security updates.",
        severity=Severity.MEDIUM,
        pattern=re.compile(
            r'required_version\s*=\s*["\'][>=<~\s]*1\.[0-2](?:\.\d+)?["\']',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="terraform_version",
        recommended_version=">= 1.5.0",
        suggested_fix="Upgrade to Terraform 1.5+ for continued security support.",
        documentation_url="https://developer.hashicorp.com/terraform/language/settings#specifying-a-required-terraform-version",
    ))
    
    # Deprecated Terraform resource patterns
    rules.append(Rule(
        id="TF006",
        category="terraform",
        title="Deprecated azurerm_container_service resource",
        description="azurerm_container_service (ACS) is deprecated. Use azurerm_kubernetes_cluster (AKS) instead.",
        severity=Severity.HIGH,
        pattern=re.compile(
            r'resource\s+["\']azurerm_container_service["\']\s+',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="azurerm_container_service",
        suggested_fix="Migrate to azurerm_kubernetes_cluster resource.",
        documentation_url="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster",
    ))
    
    rules.append(Rule(
        id="TF007",
        category="terraform",
        title="Deprecated azurerm_virtual_machine resource",
        description="azurerm_virtual_machine is deprecated. Use azurerm_linux_virtual_machine or azurerm_windows_virtual_machine.",
        severity=Severity.LOW,
        pattern=re.compile(
            r'resource\s+["\']azurerm_virtual_machine["\']\s+',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="azurerm_virtual_machine",
        suggested_fix="Migrate to azurerm_linux_virtual_machine or azurerm_windows_virtual_machine.",
        documentation_url="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine",
    ))
    
    # Deprecated attribute patterns
    rules.append(Rule(
        id="TF008",
        category="terraform",
        title="Deprecated enable_* boolean attributes",
        description="Boolean attributes using enable_* naming are deprecated in favor of *_enabled naming.",
        severity=Severity.LOW,
        pattern=re.compile(
            r'\benable_(?:pod_security_policy|http_application_routing|azure_policy)\s*=',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="azurerm_kubernetes_cluster",
        suggested_fix="Rename enable_X attributes to X_enabled (e.g., enable_azure_policy → azure_policy_enabled).",
        documentation_url="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide#resource-azurerm_kubernetes_cluster",
    ))
    
    rules.append(Rule(
        id="TF009",
        category="terraform",
        title="Deprecated container_log_max_lines attribute",
        description="container_log_max_lines has been renamed to container_log_max_files in azurerm 4.73+.",
        severity=Severity.HIGH,
        pattern=re.compile(
            r'\bcontainer_log_max_lines\s*=',
            re.IGNORECASE
        ),
        file_patterns=["*.tf"],
        resource_type="azurerm_kubernetes_cluster",
        suggested_fix="Rename container_log_max_lines to container_log_max_files.",
        documentation_url="https://github.com/hashicorp/terraform-provider-azurerm/issues/31721",
    ))
    
    # =========================================================================
    # KUBERNETES YAML RULES
    # =========================================================================
    
    # Deprecated API versions
    k8s_deprecated_apis = [
        ("extensions/v1beta1", "K8S001", Severity.CRITICAL, "apps/v1 or networking.k8s.io/v1"),
        ("apps/v1beta1", "K8S002", Severity.CRITICAL, "apps/v1"),
        ("apps/v1beta2", "K8S003", Severity.CRITICAL, "apps/v1"),
        ("networking.k8s.io/v1beta1", "K8S004", Severity.HIGH, "networking.k8s.io/v1"),
        ("batch/v1beta1", "K8S005", Severity.HIGH, "batch/v1"),
        ("policy/v1beta1", "K8S006", Severity.HIGH, "policy/v1"),
        ("autoscaling/v2beta1", "K8S007", Severity.MEDIUM, "autoscaling/v2"),
        ("autoscaling/v2beta2", "K8S008", Severity.MEDIUM, "autoscaling/v2"),
        ("certificates.k8s.io/v1beta1", "K8S009", Severity.HIGH, "certificates.k8s.io/v1"),
        ("storage.k8s.io/v1beta1", "K8S010", Severity.MEDIUM, "storage.k8s.io/v1"),
        ("admissionregistration.k8s.io/v1beta1", "K8S011", Severity.HIGH, "admissionregistration.k8s.io/v1"),
        ("rbac.authorization.k8s.io/v1beta1", "K8S012", Severity.HIGH, "rbac.authorization.k8s.io/v1"),
        ("scheduling.k8s.io/v1beta1", "K8S013", Severity.HIGH, "scheduling.k8s.io/v1"),
        ("coordination.k8s.io/v1beta1", "K8S014", Severity.HIGH, "coordination.k8s.io/v1"),
        ("discovery.k8s.io/v1beta1", "K8S015", Severity.MEDIUM, "discovery.k8s.io/v1"),
        ("flowcontrol.apiserver.k8s.io/v1beta1", "K8S016", Severity.MEDIUM, "flowcontrol.apiserver.k8s.io/v1"),
        ("flowcontrol.apiserver.k8s.io/v1beta2", "K8S017", Severity.MEDIUM, "flowcontrol.apiserver.k8s.io/v1"),
    ]
    
    for api_version, rule_id, severity, replacement in k8s_deprecated_apis:
        escaped = re.escape(api_version)
        rules.append(Rule(
            id=rule_id,
            category="kubernetes",
            title=f"Deprecated Kubernetes API version: {api_version}",
            description=f"The API version {api_version} is deprecated and may be removed in future Kubernetes versions.",
            severity=severity,
            pattern=re.compile(
                rf'apiVersion:\s*["\']?{escaped}["\']?',
                re.IGNORECASE
            ),
            file_patterns=["*.yaml", "*.yml"],
            resource_type="kubernetes_api",
            current_version=api_version,
            recommended_version=replacement,
            suggested_fix=f"Update apiVersion from {api_version} to {replacement}.",
            documentation_url="https://kubernetes.io/docs/reference/using-api/deprecation-guide/",
        ))
    
    # PodSecurityPolicy (removed in K8s 1.25)
    rules.append(Rule(
        id="K8S020",
        category="kubernetes",
        title="PodSecurityPolicy is removed",
        description="PodSecurityPolicy was removed in Kubernetes 1.25. Use Pod Security Admission instead.",
        severity=Severity.CRITICAL,
        pattern=re.compile(
            r'kind:\s*["\']?PodSecurityPolicy["\']?',
            re.IGNORECASE
        ),
        file_patterns=["*.yaml", "*.yml"],
        resource_type="PodSecurityPolicy",
        suggested_fix="Migrate to Pod Security Admission (PSA) with pod-security.kubernetes.io labels.",
        documentation_url="https://kubernetes.io/docs/concepts/security/pod-security-admission/",
    ))
    
    # =========================================================================
    # DOCKER RULES
    # =========================================================================
    
    # Deprecated base images
    docker_deprecated_images = [
        ("centos:6", "DOCKER001", Severity.CRITICAL, "rockylinux:9 or almalinux:9"),
        ("centos:7", "DOCKER002", Severity.HIGH, "rockylinux:9 or almalinux:9"),
        ("centos:8", "DOCKER003", Severity.HIGH, "rockylinux:9 or almalinux:9"),
        ("ubuntu:14.04", "DOCKER004", Severity.CRITICAL, "ubuntu:24.04"),
        ("ubuntu:16.04", "DOCKER005", Severity.HIGH, "ubuntu:24.04"),
        ("ubuntu:18.04", "DOCKER006", Severity.MEDIUM, "ubuntu:24.04"),
        ("node:10", "DOCKER010", Severity.CRITICAL, "node:20 or node:22"),
        ("node:12", "DOCKER011", Severity.HIGH, "node:20 or node:22"),
        ("node:14", "DOCKER012", Severity.HIGH, "node:20 or node:22"),
        ("node:16", "DOCKER013", Severity.MEDIUM, "node:20 or node:22"),
        ("node:18", "DOCKER014", Severity.LOW, "node:20 or node:22"),
        ("python:2", "DOCKER020", Severity.CRITICAL, "python:3.12"),
        ("python:2.7", "DOCKER021", Severity.CRITICAL, "python:3.12"),
        ("python:3.5", "DOCKER022", Severity.CRITICAL, "python:3.12"),
        ("python:3.6", "DOCKER023", Severity.HIGH, "python:3.12"),
        ("python:3.7", "DOCKER024", Severity.HIGH, "python:3.12"),
        ("python:3.8", "DOCKER025", Severity.MEDIUM, "python:3.12"),
        ("alpine:3.12", "DOCKER030", Severity.HIGH, "alpine:3.20"),
        ("alpine:3.13", "DOCKER031", Severity.HIGH, "alpine:3.20"),
        ("alpine:3.14", "DOCKER032", Severity.MEDIUM, "alpine:3.20"),
        ("alpine:3.15", "DOCKER033", Severity.MEDIUM, "alpine:3.20"),
        ("debian:stretch", "DOCKER040", Severity.HIGH, "debian:bookworm"),
        ("debian:buster", "DOCKER041", Severity.MEDIUM, "debian:bookworm"),
        ("debian:9", "DOCKER042", Severity.HIGH, "debian:12"),
        ("debian:10", "DOCKER043", Severity.MEDIUM, "debian:12"),
    ]
    
    for image, rule_id, severity, replacement in docker_deprecated_images:
        escaped = re.escape(image)
        rules.append(Rule(
            id=rule_id,
            category="docker",
            title=f"Deprecated Docker base image: {image}",
            description=f"The base image {image} is deprecated or end-of-life.",
            severity=severity,
            pattern=re.compile(
                rf'^FROM\s+{escaped}(?:\s|$|@)',
                re.IGNORECASE | re.MULTILINE
            ),
            file_patterns=["Dockerfile", "*.dockerfile", "Dockerfile.*"],
            resource_type="docker_image",
            current_version=image,
            recommended_version=replacement,
            suggested_fix=f"Update FROM {image} to FROM {replacement}.",
            documentation_url="https://endoflife.date/",
        ))
    
    # General deprecated Docker practices
    rules.append(Rule(
        id="DOCKER050",
        category="docker",
        title="Using ADD instead of COPY for local files",
        description="ADD has magic behavior (auto-extraction). Use COPY for predictable local file copies.",
        severity=Severity.INFO,
        pattern=re.compile(
            r'^ADD\s+(?!https?://)[^\s]+\s+',
            re.IGNORECASE | re.MULTILINE
        ),
        file_patterns=["Dockerfile", "*.dockerfile"],
        resource_type="dockerfile_instruction",
        suggested_fix="Use COPY instead of ADD for local files unless you need auto-extraction.",
        documentation_url="https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#add-or-copy",
    ))
    
    rules.append(Rule(
        id="DOCKER051",
        category="docker",
        title="Using latest tag",
        description="Using :latest tag makes builds non-reproducible and can cause unexpected changes.",
        severity=Severity.LOW,
        pattern=re.compile(
            r'^FROM\s+\S+:latest(?:\s|$)',
            re.IGNORECASE | re.MULTILINE
        ),
        file_patterns=["Dockerfile", "*.dockerfile"],
        resource_type="docker_image",
        suggested_fix="Pin to a specific image version/tag for reproducible builds.",
        documentation_url="https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#from",
    ))
    
    # =========================================================================
    # GITHUB ACTIONS RULES
    # =========================================================================
    
    # Deprecated action versions
    gh_deprecated_actions = [
        ("actions/checkout@v1", "GHA001", Severity.HIGH, "actions/checkout@v4"),
        ("actions/checkout@v2", "GHA002", Severity.MEDIUM, "actions/checkout@v4"),
        ("actions/checkout@v3", "GHA003", Severity.LOW, "actions/checkout@v4"),
        ("actions/setup-python@v1", "GHA010", Severity.HIGH, "actions/setup-python@v5"),
        ("actions/setup-python@v2", "GHA011", Severity.MEDIUM, "actions/setup-python@v5"),
        ("actions/setup-python@v3", "GHA012", Severity.MEDIUM, "actions/setup-python@v5"),
        ("actions/setup-python@v4", "GHA013", Severity.LOW, "actions/setup-python@v5"),
        ("actions/setup-node@v1", "GHA020", Severity.HIGH, "actions/setup-node@v4"),
        ("actions/setup-node@v2", "GHA021", Severity.MEDIUM, "actions/setup-node@v4"),
        ("actions/setup-node@v3", "GHA022", Severity.LOW, "actions/setup-node@v4"),
        ("actions/cache@v1", "GHA030", Severity.HIGH, "actions/cache@v4"),
        ("actions/cache@v2", "GHA031", Severity.MEDIUM, "actions/cache@v4"),
        ("actions/cache@v3", "GHA032", Severity.LOW, "actions/cache@v4"),
        ("actions/upload-artifact@v1", "GHA040", Severity.HIGH, "actions/upload-artifact@v4"),
        ("actions/upload-artifact@v2", "GHA041", Severity.MEDIUM, "actions/upload-artifact@v4"),
        ("actions/upload-artifact@v3", "GHA042", Severity.LOW, "actions/upload-artifact@v4"),
        ("actions/download-artifact@v1", "GHA043", Severity.HIGH, "actions/download-artifact@v4"),
        ("actions/download-artifact@v2", "GHA044", Severity.MEDIUM, "actions/download-artifact@v4"),
        ("actions/download-artifact@v3", "GHA045", Severity.LOW, "actions/download-artifact@v4"),
        ("actions/setup-go@v1", "GHA050", Severity.HIGH, "actions/setup-go@v5"),
        ("actions/setup-go@v2", "GHA051", Severity.MEDIUM, "actions/setup-go@v5"),
        ("actions/setup-go@v3", "GHA052", Severity.MEDIUM, "actions/setup-go@v5"),
        ("actions/setup-go@v4", "GHA053", Severity.LOW, "actions/setup-go@v5"),
        ("actions/setup-java@v1", "GHA060", Severity.HIGH, "actions/setup-java@v4"),
        ("actions/setup-java@v2", "GHA061", Severity.MEDIUM, "actions/setup-java@v4"),
        ("actions/setup-java@v3", "GHA062", Severity.LOW, "actions/setup-java@v4"),
        ("azure/login@v1", "GHA070", Severity.MEDIUM, "azure/login@v2"),
        ("hashicorp/setup-terraform@v1", "GHA080", Severity.MEDIUM, "hashicorp/setup-terraform@v3"),
        ("hashicorp/setup-terraform@v2", "GHA081", Severity.LOW, "hashicorp/setup-terraform@v3"),
    ]
    
    for action, rule_id, severity, replacement in gh_deprecated_actions:
        escaped = re.escape(action)
        rules.append(Rule(
            id=rule_id,
            category="github-actions",
            title=f"Deprecated GitHub Action: {action}",
            description=f"The action {action} uses a deprecated Node.js runtime or is outdated.",
            severity=severity,
            pattern=re.compile(
                rf'uses:\s*["\']?{escaped}["\']?',
                re.IGNORECASE
            ),
            file_patterns=["*.yaml", "*.yml"],
            resource_type="github_action",
            current_version=action,
            recommended_version=replacement,
            suggested_fix=f"Update from {action} to {replacement}.",
            documentation_url="https://github.blog/changelog/2023-09-22-github-actions-transitioning-from-node-16-to-node-20/",
        ))
    
    # Deprecated runs-on values
    rules.append(Rule(
        id="GHA100",
        category="github-actions",
        title="Deprecated ubuntu-18.04 runner",
        description="ubuntu-18.04 runners are deprecated and will be removed.",
        severity=Severity.HIGH,
        pattern=re.compile(
            r'runs-on:\s*["\']?ubuntu-18\.04["\']?',
            re.IGNORECASE
        ),
        file_patterns=["*.yaml", "*.yml"],
        resource_type="github_runner",
        current_version="ubuntu-18.04",
        recommended_version="ubuntu-22.04 or ubuntu-24.04",
        suggested_fix="Update runs-on from ubuntu-18.04 to ubuntu-22.04 or ubuntu-24.04.",
        documentation_url="https://github.blog/changelog/2022-08-09-github-actions-the-ubuntu-18-04-actions-runner-image-is-being-deprecated-and-will-be-removed-by-12-1-22/",
    ))
    
    rules.append(Rule(
        id="GHA101",
        category="github-actions",
        title="Deprecated macos-10.15 runner",
        description="macos-10.15 (Catalina) runners are removed.",
        severity=Severity.HIGH,
        pattern=re.compile(
            r'runs-on:\s*["\']?macos-10\.15["\']?',
            re.IGNORECASE
        ),
        file_patterns=["*.yaml", "*.yml"],
        resource_type="github_runner",
        current_version="macos-10.15",
        recommended_version="macos-14 or macos-latest",
        suggested_fix="Update runs-on from macos-10.15 to macos-14 or macos-latest.",
    ))
    
    rules.append(Rule(
        id="GHA102",
        category="github-actions",
        title="Deprecated macos-11 runner",
        description="macos-11 (Big Sur) runners are deprecated.",
        severity=Severity.MEDIUM,
        pattern=re.compile(
            r'runs-on:\s*["\']?macos-11["\']?',
            re.IGNORECASE
        ),
        file_patterns=["*.yaml", "*.yml"],
        resource_type="github_runner",
        current_version="macos-11",
        recommended_version="macos-14 or macos-latest",
        suggested_fix="Update runs-on from macos-11 to macos-14 or macos-latest.",
    ))
    
    # =========================================================================
    # SHELL SCRIPT RULES
    # =========================================================================
    
    rules.append(Rule(
        id="SHELL001",
        category="shell",
        title="Deprecated apt-key usage",
        description="apt-key is deprecated. Use signed-by option in sources.list instead.",
        severity=Severity.MEDIUM,
        pattern=re.compile(
            r'\bapt-key\s+(?:add|adv|del|export|finger|list|net-update|update)\b',
            re.IGNORECASE
        ),
        file_patterns=["*.sh", "Dockerfile", "*.dockerfile"],
        resource_type="shell_command",
        suggested_fix="Download keys to /usr/share/keyrings/ and use signed-by option in apt sources.",
        documentation_url="https://wiki.debian.org/DebianRepository/UseThirdParty",
    ))
    
    rules.append(Rule(
        id="SHELL002",
        category="shell",
        title="Python 2 interpreter reference",
        description="Python 2 is end-of-life since January 2020.",
        severity=Severity.HIGH,
        pattern=re.compile(
            r'(?:^|\s|/)python2(?:\.7)?(?:\s|$|\'|")',
            re.MULTILINE
        ),
        file_patterns=["*.sh", "Dockerfile", "*.dockerfile", "*.py"],
        resource_type="python_version",
        current_version="python2",
        recommended_version="python3",
        suggested_fix="Migrate to Python 3. Update shebang to #!/usr/bin/env python3.",
        documentation_url="https://www.python.org/doc/sunset-python-2/",
    ))
    
    rules.append(Rule(
        id="SHELL003",
        category="shell",
        title="Python 2 shebang",
        description="Scripts using #!/usr/bin/python2 shebang reference end-of-life Python 2.",
        severity=Severity.HIGH,
        pattern=re.compile(
            r'^#!\s*/usr/bin/(?:env\s+)?python2',
            re.MULTILINE
        ),
        file_patterns=["*.sh", "*.py"],
        resource_type="python_version",
        current_version="python2",
        recommended_version="python3",
        suggested_fix="Update shebang to #!/usr/bin/env python3.",
        documentation_url="https://www.python.org/doc/sunset-python-2/",
    ))
    
    rules.append(Rule(
        id="SHELL004",
        category="shell",
        title="curl with insecure flag",
        description="Using curl -k or --insecure disables certificate verification.",
        severity=Severity.MEDIUM,
        pattern=re.compile(
            r'\bcurl\s+[^|&;]*(?:-k|--insecure)\b',
            re.IGNORECASE
        ),
        file_patterns=["*.sh", "Dockerfile", "*.dockerfile"],
        resource_type="shell_command",
        suggested_fix="Remove -k/--insecure flag and ensure proper certificate verification.",
    ))
    
    rules.append(Rule(
        id="SHELL005",
        category="shell",
        title="wget with no-check-certificate",
        description="Using wget --no-check-certificate disables certificate verification.",
        severity=Severity.MEDIUM,
        pattern=re.compile(
            r'\bwget\s+[^|&;]*--no-check-certificate\b',
            re.IGNORECASE
        ),
        file_patterns=["*.sh", "Dockerfile", "*.dockerfile"],
        resource_type="shell_command",
        suggested_fix="Remove --no-check-certificate flag and ensure proper certificate verification.",
    ))
    
    rules.append(Rule(
        id="SHELL010",
        category="shell",
        title="Reference to CentOS 6 or 7",
        description="CentOS 6 and 7 are end-of-life.",
        severity=Severity.MEDIUM,
        pattern=re.compile(
            r'\bcentos[:\s-]?[67]\b',
            re.IGNORECASE
        ),
        file_patterns=["*.sh", "Dockerfile", "*.dockerfile", "*.yaml", "*.yml"],
        resource_type="os_reference",
        suggested_fix="Migrate to Rocky Linux 9, AlmaLinux 9, or another supported distribution.",
    ))
    
    rules.append(Rule(
        id="SHELL011",
        category="shell",
        title="Reference to Ubuntu 14.04 or 16.04",
        description="Ubuntu 14.04 and 16.04 are end-of-life or approaching EOL.",
        severity=Severity.MEDIUM,
        pattern=re.compile(
            r'\bubuntu[:\s-]?(?:14\.04|16\.04|trusty|xenial)\b',
            re.IGNORECASE
        ),
        file_patterns=["*.sh", "Dockerfile", "*.dockerfile", "*.yaml", "*.yml"],
        resource_type="os_reference",
        suggested_fix="Migrate to Ubuntu 22.04 (Jammy) or Ubuntu 24.04 (Noble).",
    ))
    
    # =========================================================================
    # GENERAL / MISCELLANEOUS RULES
    # =========================================================================
    
    rules.append(Rule(
        id="GEN001",
        category="general",
        title="Hardcoded credentials pattern",
        description="Potential hardcoded password or API key detected.",
        severity=Severity.HIGH,
        pattern=re.compile(
            r'(?:password|api_key|apikey|secret|token)\s*[=:]\s*["\'][^"\']{8,}["\']',
            re.IGNORECASE
        ),
        file_patterns=["*.tf", "*.tfvars", "*.yaml", "*.yml", "*.sh", "*.env"],
        resource_type="credentials",
        suggested_fix="Use environment variables, secret management, or Terraform variables for sensitive values.",
    ))
    
    rules.append(Rule(
        id="GEN002",
        category="general",
        title="HTTP URL (not HTTPS)",
        description="Using HTTP instead of HTTPS for downloading resources.",
        severity=Severity.LOW,
        pattern=re.compile(
            r'http://(?!localhost|127\.0\.0\.1|0\.0\.0\.0)',
            re.IGNORECASE
        ),
        file_patterns=["*.tf", "*.yaml", "*.yml", "*.sh", "Dockerfile"],
        resource_type="url",
        suggested_fix="Use HTTPS for secure communication.",
    ))
    
    return rules


# Module-level rule catalog
DEPRECATION_RULES: List[Rule] = _build_rules()


def get_rules_for_category(category: str) -> List[Rule]:
    """Get all rules for a specific category."""
    return [r for r in DEPRECATION_RULES if r.category == category and r.enabled]


def get_rules_for_file(filename: str) -> List[Rule]:
    """Get all rules that apply to a specific filename."""
    import fnmatch
    
    applicable = []
    for rule in DEPRECATION_RULES:
        if not rule.enabled:
            continue
        for pattern in rule.file_patterns:
            if fnmatch.fnmatch(filename, pattern) or fnmatch.fnmatch(filename.lower(), pattern.lower()):
                applicable.append(rule)
                break
    return applicable


def get_rule_by_id(rule_id: str) -> Optional[Rule]:
    """Get a specific rule by its ID."""
    for rule in DEPRECATION_RULES:
        if rule.id == rule_id:
            return rule
    return None
