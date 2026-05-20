"""Future deprecation intelligence for IaC scanner.

This module provides a local-first implementation that:
- extracts repository component versions and APIs
- correlates them with known future lifecycle risks
- enriches output with manifest scanner upgrade impact

Design goals:
- minimal dependencies (stdlib only)
- deterministic behavior for Innovation Week POC
- graceful fallback to local seed data
"""

import json
import os
import re
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

from .live_fetcher import build_live_seed


def _safe_read(path: str) -> str:
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()


def _walk_files(repo_root: str) -> List[str]:
    skip_dirs = {
        ".git",
        ".terraform",
        ".terragrunt-cache",
        "node_modules",
        ".venv",
        "venv",
        "__pycache__",
        ".pytest_cache",
        ".mypy_cache",
        ".tox",
        "dist",
        "build",
        "target",
        "vendor",
    }

    out: List[str] = []
    for root, dirs, files in os.walk(repo_root):
        rel_root = os.path.relpath(root, repo_root).replace("\\", "/")
        if rel_root.startswith(".github/tools"):
            dirs[:] = []
            continue
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        for name in files:
            out.append(os.path.join(root, name))
    return out


def _parse_semver(raw: str) -> Tuple[int, int, int]:
    m = re.search(r"(\d+)\.(\d+)(?:\.(\d+))?", raw or "")
    if not m:
        return (0, 0, 0)
    return (int(m.group(1)), int(m.group(2)), int(m.group(3) or 0))


def _semver_lt(a: str, b: str) -> bool:
    return _parse_semver(a) < _parse_semver(b)


def _major_from_ref(version: str) -> str:
    if not version:
        return ""
    m = re.match(r"v?(\d+)", version.strip())
    return f"v{m.group(1)}" if m else version.strip()


def extract_repository_inventory(repo_root: str) -> Dict[str, Any]:
    """Extract versions and components used by the repository."""

    providers: List[Dict[str, str]] = []
    k8s_versions: List[Dict[str, str]] = []
    k8s_apis: List[Dict[str, str]] = []
    github_actions: List[Dict[str, str]] = []
    helm_versions: List[Dict[str, str]] = []
    container_images: List[Dict[str, str]] = []
    tools: List[Dict[str, str]] = []
    azure_resources: List[Dict[str, Any]] = []

    provider_re = re.compile(r"(\w+)\s*=\s*\{[^}]*?version\s*=\s*\"([^\"]+)\"", re.DOTALL)
    k8s_version_re = re.compile(r"\bkubernetes_version\s*=\s*\"([0-9]+\.[0-9]+(?:\.[0-9]+)?)\"")
    api_version_re = re.compile(r"\bapiVersion\s*:\s*([A-Za-z0-9./-]+)")
    action_re = re.compile(r"uses:\s*([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)@([^\s]+)")
    image_re = re.compile(r"\bimage\s*:\s*([^\s#]+)")
    from_re = re.compile(r"^\s*FROM\s+([^\s]+)", re.MULTILINE)
    helm_chart_ver_re = re.compile(r"^\s*version:\s*(.+)$", re.MULTILINE)
    helm_app_ver_re = re.compile(r"^\s*appVersion:\s*(.+)$", re.MULTILINE)
    terraform_version_re = re.compile(r"\brequired_version\s*=\s*\"([^\"]+)\"")

    for fpath in _walk_files(repo_root):
        rel = os.path.relpath(fpath, repo_root).replace("\\", "/")
        name = os.path.basename(fpath)
        text = _safe_read(fpath)

        if name == "versions.tf" or rel.endswith("/versions.tf"):
            for pname, pver in provider_re.findall(text):
                providers.append({"name": pname, "version": pver, "file": rel})
            for m in terraform_version_re.findall(text):
                tools.append({"name": "terraform", "version": m, "file": rel})

        if rel.endswith(".tfvars") or rel.endswith(".tf"):
            for kv in k8s_version_re.findall(text):
                k8s_versions.append({"version": kv, "file": rel})

        if rel.endswith(".yml") or rel.endswith(".yaml"):
            for api in api_version_re.findall(text):
                k8s_apis.append({"api_version": api, "file": rel})
            for action, ver in action_re.findall(text):
                github_actions.append({"action": action, "version": ver, "file": rel})
            for image in image_re.findall(text):
                container_images.append({"image": image, "file": rel})

        if name.startswith("Dockerfile") or name == "dockerfile":
            for image in from_re.findall(text):
                container_images.append({"image": image, "file": rel})

        if name == "Chart.yaml":
            for ver in helm_chart_ver_re.findall(text):
                helm_versions.append({"name": "chart", "version": ver.strip().strip('"'), "file": rel})
            for ver in helm_app_ver_re.findall(text):
                helm_versions.append({"name": "appVersion", "version": ver.strip().strip('"'), "file": rel})

    # Add azure resources from generated manifest if available
    manifest_path = os.path.join(repo_root, ".iac-manifest.json")
    if os.path.exists(manifest_path):
        try:
            manifest = json.loads(_safe_read(manifest_path))
            files = manifest.get("files", {})
            for rel_file, fd in files.items():
                resources = fd.get("resources", {})
                for rtype in resources.keys():
                    azure_resources.append({"resource_type": rtype, "file": rel_file})
        except Exception:
            pass

    # Deduplicate while preserving order
    def dedupe(items: List[Dict[str, str]], keys: Tuple[str, ...]) -> List[Dict[str, str]]:
        seen = set()
        out = []
        for it in items:
            marker = tuple(it.get(k, "") for k in keys)
            if marker in seen:
                continue
            seen.add(marker)
            out.append(it)
        return out

    return {
        "providers": dedupe(providers, ("name", "version", "file")),
        "kubernetes_versions": dedupe(k8s_versions, ("version", "file")),
        "kubernetes_api_versions": dedupe(k8s_apis, ("api_version", "file")),
        "github_actions": dedupe(github_actions, ("action", "version", "file")),
        "helm_versions": dedupe(helm_versions, ("name", "version", "file")),
        "container_images": dedupe(container_images, ("image", "file")),
        "tool_versions": dedupe(tools, ("name", "version", "file")),
        "azure_resources": dedupe(azure_resources, ("resource_type", "file")),
    }


def _load_seed_data(scanner_root: str) -> Dict[str, Any]:
    seed_path = os.path.join(scanner_root, "data", "future_intelligence_seed.json")
    if not os.path.exists(seed_path):
        return {}
    try:
        return json.loads(_safe_read(seed_path))
    except Exception:
        return {}


def _load_cache(cache_path: str, ttl_hours: int = 24) -> Optional[Dict[str, Any]]:
    if not os.path.exists(cache_path):
        return None
    try:
        payload = json.loads(_safe_read(cache_path))
    except Exception:
        return None

    fetched = payload.get("fetched_at")
    if not fetched:
        return None

    try:
        fetched_at = datetime.fromisoformat(fetched)
    except Exception:
        return None

    if datetime.utcnow() - fetched_at > timedelta(hours=ttl_hours):
        return None
    return payload


def _save_cache(cache_path: str, payload: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(cache_path), exist_ok=True)
    with open(cache_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def correlate_future_risks(
    repo_inventory: Dict[str, Any],
    seed_data: Dict[str, Any],
    manifest_report: Optional[Dict[str, Any]] = None,
) -> Tuple[List[Dict[str, Any]], List[str]]:
    """Build upcoming/future risk findings from repo inventory and intelligence rules."""

    risks: List[Dict[str, Any]] = []
    summaries: List[str] = []

    # 1) Terraform provider lifecycle and upgrade-lag risks
    latest_azurerm = None
    if manifest_report:
        ms = manifest_report.get("summary", {})
        latest_azurerm = ms.get("latest_version")
    # Fall back to live-fetched value when manifest scanner was not run
    if not latest_azurerm:
        latest_azurerm = seed_data.get("_live_azurerm_latest")

    for p in repo_inventory.get("providers", []):
        if p.get("name") != "azurerm":
            continue
        current = p.get("version", "")

        if latest_azurerm and _semver_lt(current, latest_azurerm):
            severity = "HIGH" if _parse_semver(latest_azurerm)[1] - _parse_semver(current)[1] >= 10 else "MEDIUM"
            risks.append({
                "severity": severity,
                "component": "azurerm provider",
                "component_type": "terraform_provider",
                "current_version": current,
                "future_risk": f"Provider drift detected relative to latest stable {latest_azurerm}; future upgrades may include cumulative breaking changes.",
                "effective_date": "Before next provider upgrade cycle",
                "impact": "Multiple Terraform resources may require config adjustments during upgrade.",
                "source": "azurerm changelog and upgrade guidance",
                "source_url": "https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide",
                "file": p.get("file", ""),
                "needs_verification": False,
            })

        if manifest_report:
            affected = manifest_report.get("affected_resources", [])
            affected_types = [a.get("resource_type") for a in affected if a.get("severity") in ("BREAKING", "DEPRECATED")]
            if affected_types:
                top = ", ".join(affected_types[:5])
                summaries.append(
                    "Upgrading azurerm may impact: " + top + (" ..." if len(affected_types) > 5 else "")
                )

    # 2) Kubernetes minor support lifecycle risks
    support_map = seed_data.get("kubernetes_minor_support", {})
    for kv in repo_inventory.get("kubernetes_versions", []):
        full = kv.get("version", "")
        parts = _parse_semver(full)
        minor_key = f"{parts[0]}.{parts[1]}"
        support_info = support_map.get(minor_key)
        if not support_info:
            continue

        support_end = support_info.get("support_end")
        sev = "LOW"
        effective_date = support_end or "Upcoming"
        try:
            days = (datetime.fromisoformat(support_end) - datetime.utcnow()).days
            if days <= 180:
                sev = "HIGH"
            elif days <= 365:
                sev = "MEDIUM"
        except Exception:
            sev = "MEDIUM"

        risks.append({
            "severity": sev,
            "component": "AKS Kubernetes version",
            "component_type": "kubernetes_version",
            "current_version": full,
            "future_risk": f"Kubernetes minor {minor_key} approaches support lifecycle boundary.",
            "effective_date": effective_date,
            "impact": "Cluster and node pool upgrades may be required to remain in full support.",
            "source": support_info.get("source", "AKS support policy"),
            "source_url": "https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions",
            "file": kv.get("file", ""),
            "needs_verification": False,
        })

    # 3) Kubernetes API removals
    removed_apis = seed_data.get("kubernetes_removed_apis", {})
    for api in repo_inventory.get("kubernetes_api_versions", []):
        api_ver = api.get("api_version")
        info = removed_apis.get(api_ver)
        if not info:
            continue
        risks.append({
            "severity": "HIGH",
            "component": f"Kubernetes API {api_ver}",
            "component_type": "kubernetes_api",
            "current_version": api_ver,
            "future_risk": f"API removed in Kubernetes {info.get('removed_in')}.",
            "effective_date": f"Removed in {info.get('removed_in')}",
            "impact": f"Workloads using {api_ver} can fail apply/reconcile on supported AKS versions.",
            "source": info.get("source", "Kubernetes deprecation guide"),
            "source_url": "https://kubernetes.io/docs/reference/using-api/deprecation-guide/",
            "file": api.get("file", ""),
            "needs_verification": False,
            "recommended_replacement": info.get("replacement", "")
        })

    # 4) GitHub Actions lifecycle risks
    gha_map = seed_data.get("github_actions_runtime_risks", {})
    for action in repo_inventory.get("github_actions", []):
        name = action.get("action", "")
        ver = _major_from_ref(action.get("version", ""))
        action_rules = gha_map.get(name, {})
        ver_rule = action_rules.get(ver)
        if not ver_rule:
            continue
        risks.append({
            "severity": ver_rule.get("severity", "LOW"),
            "component": name,
            "component_type": "github_action",
            "current_version": action.get("version", ""),
            "future_risk": ver_rule.get("future_risk", "Action major version is behind current recommendations."),
            "effective_date": "Upcoming",
            "impact": "CI pipeline reliability and compatibility risk.",
            "source": ver_rule.get("source", "GitHub Actions changelog"),
            "source_url": "https://github.blog/changelog/2023-09-22-github-actions-transitioning-from-node-16-to-node-20/",
            "file": action.get("file", ""),
            "recommended_replacement": ver_rule.get("recommended_version", ""),
            "needs_verification": False,
        })

    # 5) Manifest-based upcoming upgrade risk entry
    if manifest_report:
        ms = manifest_report.get("summary", {})
        status = ms.get("status")
        breaking = ms.get("breaking_count", 0)
        changed = ms.get("changed_count", 0)
        if status == "REVIEW_REQUIRED":
            severity = "HIGH" if breaking else "MEDIUM"
            risks.append({
                "severity": severity,
                "component": "azurerm provider upgrade window",
                "component_type": "terraform_provider",
                "current_version": ms.get("current_version", ""),
                "future_risk": f"Upgrade window {ms.get('current_version', '?')} -> {ms.get('latest_version', '?')} contains {breaking} breaking and {changed} changed items.",
                "effective_date": "Next provider upgrade",
                "impact": "Terraform plans may introduce recreations, diffs, or failures until resource configuration is aligned.",
                "source": "Manifest scanner changelog analysis",
                "source_url": "https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md",
                "file": "deprecation-report.json",
                "needs_verification": False,
            })

    # Stable ordering by severity then component
    order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2, "INFO": 3}
    risks.sort(key=lambda r: (order.get(r.get("severity", "INFO"), 99), r.get("component", "")))

    # Deduplicate near-identical entries
    deduped: List[Dict[str, Any]] = []
    seen = set()
    for r in risks:
        marker = (r.get("component"), r.get("current_version"), r.get("future_risk"), r.get("file"))
        if marker in seen:
            continue
        seen.add(marker)
        deduped.append(r)

    if not summaries and manifest_report:
        affected = manifest_report.get("affected_resources", [])
        if affected:
            top = ", ".join(a.get("resource_type", "") for a in affected[:5])
            summaries.append("Potential upgrade impact touches: " + top + (" ..." if len(affected) > 5 else ""))

    return deduped, summaries


def build_future_deprecation_intelligence(
    repo_root: str,
    scanner_root: str,
    manifest_report: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Produce future deprecation intelligence report payload."""

    cache_path = os.path.join(scanner_root, "data", "future_intelligence_cache.json")
    cached = _load_cache(cache_path, ttl_hours=24)

    if cached:
        seed_data = cached.get("seed_data", {})
        cache_used = True
    else:
        static_seed = _load_seed_data(scanner_root)
        print("  Fetching live lifecycle data (K8s, azurerm, GitHub Actions)...")
        seed_data = build_live_seed(static_seed)
        fetch_status = seed_data.get("_fetch_status", {})
        print(f"    kubernetes  : {fetch_status.get('kubernetes', 'unknown')}")
        print(f"    azurerm     : {fetch_status.get('azurerm', 'unknown')}")
        print(f"    gha actions : {fetch_status.get('github_actions', {})}")
        cache_used = False
        _save_cache(
            cache_path,
            {
                "fetched_at": datetime.utcnow().isoformat(),
                "seed_data": seed_data,
            },
        )

    inventory = extract_repository_inventory(repo_root)
    risks, summaries = correlate_future_risks(inventory, seed_data, manifest_report)

    return {
        "metadata": {
            "generated_at": datetime.utcnow().isoformat(),
            "cache_used": cache_used,
            "sources": seed_data.get("sources", []),
            "model": "rule-based-future-intel-v1",
        },
        "repository_inventory": inventory,
        "upcoming_risks": risks,
        "upgrade_impact_summaries": summaries,
    }
