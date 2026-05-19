#!/usr/bin/env python3
# Copyright © 2026, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
# IaC Deprecation Checker — runs locally or via Copilot agent
#
# Severity levels:
#   BREAKING   — argument/resource already removed or renamed; WILL break on upgrade
#   DEPRECATED — explicitly marked deprecated; still works, removal planned in a future version
#   CHANGED    — behaviour or bug-fix change; review recommended before upgrading
#
# Usage (from repo root):
#   python tools/manifest/check_deprecations.py
#   python tools/manifest/check_deprecations.py --root /path/to/repo

import json
import os
import re
import argparse
import urllib.request
import urllib.error
from datetime import date, datetime, timezone


REGISTRY_API   = "https://registry.terraform.io/v1/providers/hashicorp/azurerm"
CHANGELOG_URL  = "https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/CHANGELOG.md"


def fetch_url(url, label):
    print(f"  Fetching {label}...")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "iac-deprecation-checker/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.read().decode("utf-8")
    except urllib.error.URLError as e:
        print(f"\n  ERROR: Could not reach {url}")
        print(f"  Reason: {e.reason}")
        print("  Check your internet connection and try again.")
        raise SystemExit(1)


def get_latest_version():
    content = fetch_url(REGISTRY_API, "Terraform Registry (latest azurerm version)")
    data = json.loads(content)
    return data.get("version", "unknown")


def extract_changelog_delta(changelog, old_version, new_version):
    pattern = rf"(## {re.escape(new_version)}.*?)(?=## {re.escape(old_version)}|\Z)"
    match = re.search(pattern, changelog, re.DOTALL)
    if match:
        return match.group(1)
    print("  WARNING: Could not isolate changelog section precisely. Using full changelog as fallback.")
    return changelog


def load_manifest(manifest_path):
    if not os.path.exists(manifest_path):
        print(f"\nERROR: {manifest_path} not found.")
        print("Run this first:  python .github/tools/manifest/generate_manifest.py")
        raise SystemExit(1)
    with open(manifest_path, "r", encoding="utf-8") as f:
        return json.load(f)


def get_your_resource_types(manifest):
    types = set()
    for file_data in manifest.get("files", {}).values():
        types.update(file_data.get("resources", {}).keys())
        types.update(file_data.get("data_sources", {}).keys())
    return sorted(types)


def classify_severity(lines):
    """
    Highest severity across all changelog lines for one resource.
      BREAKING   — already removed/renamed in this range
      DEPRECATED — explicitly deprecated; still works
      CHANGED    — behaviour change worth reviewing
    """
    severity = "CHANGED"
    for line in lines:
        low = line.lower()
        if re.search(r'\bremov(ed|al|ing)\b|\brenam(ed|ing)\b|\bbroken\b|\bbreaking\b', low):
            return "BREAKING"
        m = re.search(r'`([^`]+)`\s+(?:property\s+)?has been renamed to\s+`([^`]+)`', line, re.IGNORECASE)
        if m:
            return f"BREAKING: property `{m.group(1)}` renamed to `{m.group(2)}` — update your .tf files before upgrading"
        if re.search(r'\bdeprecate[ds]?\b', low):
            severity = "DEPRECATED"
    return severity


def extract_lifecycle_note(lines):
    """Return a human-readable note about when/how the resource is affected."""
    for line in lines:
        low = line.lower()
        # Rename: property X has been renamed to Y
        m = re.search(r'`([^`]+)`\s+(?:property\s+)?has been renamed to\s+`([^`]+)`', line, re.IGNORECASE)
        if m:
            return "BREAKING: property `" + m.group(1) + "` renamed to `" + m.group(2) + "` -- update your .tf files before upgrading"
        # Deprecation with replacement
        m = re.search(r'deprecate[ds]?\s+`?(\w+)`?\s+in favour of\s+`?(\w+)`?', low)
        if m:
            return "Deprecated: `" + m.group(1) + "` replaced by `" + m.group(2) + "` -- still works but will be removed in a future major release"
        # Already removed
        if re.search(r'remov(ed|al)', low):
            return "Already removed in this version range -- upgrade WILL break without code changes first"
        # Generic deprecation
        if re.search(r'deprecate[ds]?', low):
            return "Deprecated in this version range -- still functional until a future major release"
    return None

def find_affected_resources(resource_types, changelog_delta):
    """
    Return sorted list of dicts: { resource_type, severity, lifecycle_note, changelog_lines }
    Sorted: BREAKING → DEPRECATED → CHANGED
    """
    affected = []
    for rtype in resource_types:
        matches = [
            line.strip()
            for line in changelog_delta.splitlines()
            if re.search(re.escape(rtype), line, re.IGNORECASE) and line.strip().startswith("*")
        ]
        if matches:
            severity       = classify_severity(matches)
            lifecycle_note = extract_lifecycle_note(matches)
            affected.append({
                "resource_type":   rtype,
                "severity":        severity,
                "lifecycle_note":  lifecycle_note,
                "changelog_lines": matches,
            })
    order = {"BREAKING": 0, "DEPRECATED": 1, "CHANGED": 2}
    affected.sort(key=lambda x: order.get(x["severity"], 9))
    return affected


def find_files_for_resource(manifest, resource_type):
    files = []
    for path, file_data in manifest.get("files", {}).items():
        if resource_type in file_data.get("resources", {}) or \
           resource_type in file_data.get("data_sources", {}):
            files.append(path)
    return files


def main():
    parser = argparse.ArgumentParser(
        description="Check azurerm Terraform resources for deprecations"
    )
    parser.add_argument("--root", default=".", help="Root directory of the Terraform repo")
    args = parser.parse_args()

    root = os.path.abspath(args.root)
    manifest_path = os.path.join(root, ".iac-manifest.json")
    report_path   = os.path.join(root, "deprecation-report.json")

    print("=" * 60)
    print("  IaC Deprecation Checker")
    print(f"  Date: {date.today().isoformat()}")
    print("=" * 60)

    manifest       = load_manifest(manifest_path)
    old_version    = manifest.get("last_checked_version", "unknown")
    last_checked   = manifest.get("last_checked_date", "unknown")
    resource_types = get_your_resource_types(manifest)

    print(f"\nManifest")
    print(f"  Last checked version : {old_version}")
    print(f"  Last checked date    : {last_checked}")
    print(f"  Resource types found : {len(resource_types)}")

    print("\nChecking Terraform Registry...")
    latest_version = get_latest_version()
    print(f"  Latest azurerm version: {latest_version}")
    print(f"  Your azurerm version  : {old_version}")

    report = {
        "metadata": {
            "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "tool":         "iac-deprecation-checker",
            "repo":         os.path.basename(root),
        },
        "summary": {
            "status":           "UP_TO_DATE",
            "current_version":  old_version,
            "latest_version":   latest_version,
            "total_resources":  len(resource_types),
            "affected_count":   0,
            "breaking_count":   0,
            "deprecated_count": 0,
            "changed_count":    0,
            "changelog_range":  f"{old_version} to {latest_version}",
        },
        "affected_resources": [],
        "references": {
            "terraform_registry": f"https://registry.terraform.io/providers/hashicorp/azurerm/{latest_version}/docs",
            "changelog":          "https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md",
        },
    }

    if old_version == latest_version:
        print("\nYou are on the latest version. No action needed.")
        _write_report(report, report_path)
        return

    print(f"\n  Upgrade available: {old_version} to {latest_version}")

    print("\nFetching CHANGELOG...")
    changelog_full = fetch_url(CHANGELOG_URL, "azurerm CHANGELOG")
    print(f"  CHANGELOG size: {len(changelog_full.splitlines())} lines")

    delta = extract_changelog_delta(changelog_full, old_version, latest_version)
    print(f"  Delta section: {len(delta.splitlines())} lines ({old_version} to {latest_version})")

    print("\nCross-referencing your resources against CHANGELOG...")
    affected = find_affected_resources(resource_types, delta)

    breaking_count   = sum(1 for r in affected if r["severity"] == "BREAKING")
    deprecated_count = sum(1 for r in affected if r["severity"] == "DEPRECATED")
    changed_count    = sum(1 for r in affected if r["severity"] == "CHANGED")

    affected_entries = []
    for item in affected:
        files = find_files_for_resource(manifest, item["resource_type"])
        affected_entries.append({
            "resource_type":   item["resource_type"],
            "files":           files,
            "severity":        item["severity"],
            "lifecycle_note":  item["lifecycle_note"],
            "changelog_lines": item["changelog_lines"],
        })

    report["summary"]["status"]           = "REVIEW_REQUIRED" if affected else "UP_TO_DATE"
    report["summary"]["affected_count"]   = len(affected)
    report["summary"]["breaking_count"]   = breaking_count
    report["summary"]["deprecated_count"] = deprecated_count
    report["summary"]["changed_count"]    = changed_count
    report["affected_resources"]          = affected_entries

    severity_icon = {"BREAKING": "BREAKING", "DEPRECATED": "DEPRECATED", "CHANGED": "CHANGED"}

    print()
    print("=" * 60)

    if not affected:
        print("NO CHANGES DETECTED")
        print(f"\n  Checked {len(resource_types)} resource types against the")
        print(f"  {old_version} to {latest_version} changelog.")
        print("  None of your resources appear in the changelog.")
        print("\n  Safe to upgrade azurerm in versions.tf.")
    else:
        print("REVIEW REQUIRED BEFORE UPGRADING")
        print(f"\n  {len(affected)} of your {len(resource_types)} resource type(s) appear in the")
        print(f"  {old_version} to {latest_version} changelog.")
        print(f"\n  [BREAKING]   {breaking_count}  - will break on upgrade without code changes first")
        print(f"  [DEPRECATED] {deprecated_count}  - still works, removal planned in a future major release")
        print(f"  [CHANGED]    {changed_count}  - behaviour change, review before upgrading")
        print()

        for entry in affected_entries:
            print(f"  [{entry['severity']}] {entry['resource_type']}")
            for f in entry["files"]:
                print(f"       -> {f}")
            if entry["lifecycle_note"]:
                print(f"       NOTE: {entry['lifecycle_note']}")
            for cl in entry["changelog_lines"]:
                print(f"       {cl}")
            print()

        print("  Action:")
        print(f"  1. Review: https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md")
        print("  2. Check the files listed above for affected arguments")
        if breaking_count:
            print("  ** BREAKING items must be fixed BEFORE upgrading versions.tf **")
        if deprecated_count:
            print("  ** DEPRECATED items still work - plan migration before next major release **")

    print()
    print("=" * 60)

    _write_report(report, report_path)

    manifest["last_checked_date"] = date.today().isoformat()
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"\n  Manifest last_checked_date updated to {date.today().isoformat()}")


def _write_report(report, report_path):
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    status = report["summary"]["status"]
    print(f"\n  Report written : {report_path}")
    print(f"  Status         : {status}")


if __name__ == "__main__":
    main()
