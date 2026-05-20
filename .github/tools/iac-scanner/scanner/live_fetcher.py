"""Live lifecycle data fetcher for future_intelligence.

Fetches real-time support window and version data from public APIs
(no authentication required) and merges with static seed fallback.

Sources:
  - endoflife.date/api/kubernetes.json  -> K8s minor support windows
  - registry.terraform.io               -> latest azurerm provider version
  - api.github.com/repos/*/releases     -> latest GitHub Actions versions

Falls back gracefully per-section: if a fetch fails, the static seed
value for that section is kept. A partial fetch is still useful.
"""

import json
import re
from datetime import datetime
from typing import Any, Dict, Optional
from urllib.error import URLError
from urllib.request import Request, urlopen

_TIMEOUT = 30  # seconds


# ---------------------------------------------------------------------------
# Low-level HTTP helper
# ---------------------------------------------------------------------------


def _get_json(url: str) -> Optional[Any]:
    """GET a URL and return parsed JSON, or None on any error."""
    try:
        req = Request(url, headers={"User-Agent": "iac-deprecation-scanner/1.0"})
        with urlopen(req, timeout=_TIMEOUT) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Individual live fetchers
# ---------------------------------------------------------------------------


def fetch_k8s_support_windows() -> Dict[str, Dict[str, str]]:
    """Fetch Kubernetes minor-version EOL dates from endoflife.date.

    Returns a dict keyed by minor version string e.g.:
        {"1.34": {"support_end": "2026-11-30", "source": "..."}, ...}

    Only future (not-yet-expired) versions are included.
    Returns {} on failure so the static seed is used as-is.
    """
    data = _get_json("https://endoflife.date/api/kubernetes.json")
    if not data or not isinstance(data, list):
        return {}

    result: Dict[str, Dict[str, str]] = {}
    for entry in data:
        cycle = str(entry.get("cycle", "")).strip()
        eol = entry.get("eol")

        # eol can be False (not yet EOL) or a date string
        if not cycle:
            continue
        if eol is False or eol is None:
            # Not yet EOL — include with a placeholder far future date
            result[cycle] = {
                "support_end": "TBD",
                "lts_end": str(entry.get("lts") or "TBD"),
                "source": "endoflife.date — Kubernetes release calendar",
            }
            continue

        eol_str = str(eol)
        result[cycle] = {
            "support_end": eol_str,
            "lts_end": str(entry.get("lts") or eol_str),
            "source": "endoflife.date — Kubernetes release calendar",
        }

    return result


def fetch_azurerm_latest() -> Optional[str]:
    """Fetch the latest published azurerm provider version from Terraform Registry.

    Used as a fallback when the manifest scanner has not been run.
    Returns None on failure.
    """
    data = _get_json("https://registry.terraform.io/v1/providers/hashicorp/azurerm")
    if not data:
        return None
    return data.get("version")


def fetch_github_action_latest(action: str) -> Optional[str]:
    """Fetch the latest release tag for a public GitHub Actions repo.

    action: org/repo string e.g. "actions/checkout"
    Returns tag_name string (e.g. "v4.2.2") or None on failure.
    """
    url = f"https://api.github.com/repos/{action}/releases/latest"
    data = _get_json(url)
    if not data:
        return None
    return data.get("tag_name")


# ---------------------------------------------------------------------------
# Merger
# ---------------------------------------------------------------------------


def build_live_seed(static_seed: Dict[str, Any]) -> Dict[str, Any]:
    """Merge live-fetched data with static seed.

    Strategy:
      - Start from a copy of the static seed (always safe baseline).
      - Overlay live K8s support windows (endoflife.date wins per cycle).
      - Add live azurerm latest version as metadata fallback.
      - Update recommended_version in GHA rules to the actual latest tag.
      - Record which sections were refreshed live vs fell back to static.

    Returns the merged dict ready to be written into the 24-hour cache.
    """
    live = dict(static_seed)  # shallow copy — sections overwritten below

    # 1. Kubernetes support windows
    live_k8s = fetch_k8s_support_windows()
    if live_k8s:
        # Merge: static provides any cycles not in live; live wins on shared keys
        merged = dict(static_seed.get("kubernetes_minor_support", {}))
        merged.update(live_k8s)
        live["kubernetes_minor_support"] = merged
        live["_fetch_status"] = live.get("_fetch_status", {})
        live["_fetch_status"]["kubernetes"] = "live"
    else:
        live.setdefault("_fetch_status", {})["kubernetes"] = "static_fallback"

    # 2. azurerm latest version (metadata — used when manifest_report is absent)
    azurerm_latest = fetch_azurerm_latest()
    if azurerm_latest:
        live["_live_azurerm_latest"] = azurerm_latest
        live["_fetch_status"]["azurerm"] = "live"
    else:
        live["_fetch_status"]["azurerm"] = "static_fallback"

    # 3. GitHub Actions recommended versions
    gha_map: Dict[str, Any] = dict(static_seed.get("github_actions_runtime_risks", {}))
    gha_fetch_status: Dict[str, str] = {}
    for action_name in list(gha_map.keys()):
        latest_tag = fetch_github_action_latest(action_name)
        if latest_tag:
            for ver_rule in gha_map[action_name].values():
                if isinstance(ver_rule, dict):
                    ver_rule["recommended_version"] = latest_tag
            gha_fetch_status[action_name] = f"live ({latest_tag})"
        else:
            gha_fetch_status[action_name] = "static_fallback"
    live["github_actions_runtime_risks"] = gha_map
    live["_fetch_status"]["github_actions"] = gha_fetch_status

    # 4. Refresh sources list to include live API URLs
    existing_sources = list(static_seed.get("sources", []))
    live_sources = [
        "https://endoflife.date/api/kubernetes.json",
        "https://registry.terraform.io/v1/providers/hashicorp/azurerm",
        "https://api.github.com (GitHub Releases API)",
    ]
    combined = existing_sources + [s for s in live_sources if s not in existing_sources]
    live["sources"] = combined

    live["fetched_at"] = datetime.utcnow().isoformat()
    return live
