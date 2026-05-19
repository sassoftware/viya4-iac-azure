#!/usr/bin/env python3
# Copyright © 2026, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
# IaC Manifest Generator
# Scans all .tf files in the repo and produces .iac-manifest.json
#
# Usage (from repo root):
#   python3 tools/manifest/generate_manifest.py
#   python3 tools/manifest/generate_manifest.py --root /path/to/repo
#
# Requirements: Python 3.6+ standard library only — no pip installs needed

import os
import re
import json
import hashlib
import argparse
from datetime import date

# Directories to skip during scan
SKIP_DIRS = {"test", "examples", ".terraform", ".git", ".github"}


def hash_file(path):
    """Compute SHA256 hash of a file."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        h.update(f.read())
    return h.hexdigest()


def get_azurerm_version(root):
    """Extract the exact azurerm provider version from versions.tf."""
    versions_file = os.path.join(root, "versions.tf")
    if not os.path.exists(versions_file):
        print("  WARNING: versions.tf not found, version set to 'unknown'")
        return "unknown"
    with open(versions_file, "r", encoding="utf-8") as f:
        content = f.read()
    # Match: azurerm = { ... version = "4.48.0" ... }
    match = re.search(
        r'azurerm\s*=\s*\{[^}]*version\s*=\s*"([^"]+)"', content, re.DOTALL
    )
    return match.group(1) if match else "unknown"


def extract_blocks(content):
    """
    Extract resource and data blocks from .tf file content.
    Returns (resources dict, data_sources dict).
    Each entry: { "resource_type": { "arguments": ["arg1", "arg2", ...] } }
    Only top-level arguments (key = value) are captured — nested blocks are skipped.
    """
    resources = {}
    data_sources = {}
    lines = content.split("\n")
    i = 0

    while i < len(lines):
        line = lines[i]

        # Match: resource "azurerm_type" "label" {
        res_match = re.match(r'\s*resource\s+"([^"]+)"\s+"[^"]+"\s*\{', line)
        # Match: data "azurerm_type" "label" {
        data_match = re.match(r'\s*data\s+"([^"]+)"\s+"[^"]+"\s*\{', line)

        if res_match or data_match:
            block_type = (res_match or data_match).group(1)
            target = resources if res_match else data_sources

            args = set()
            # Count braces on the declaration line itself to handle one-liners:
            # e.g. data "azurerm_subscription" "current" {}
            # has both { and } on the same line — depth must start at 0 for those
            depth = line.count("{") - line.count("}")
            i += 1

            while i < len(lines) and depth > 0:
                l = lines[i]

                # At depth 1 we are directly inside the resource block
                # Capture: "  key = value" — not "  nested_block {"
                if depth == 1:
                    arg_match = re.match(r"[ \t]{2,}(\w+)\s*=\s*\S", l)
                    if arg_match:
                        args.add(arg_match.group(1))

                # Track brace depth — strings with { or } are an edge case we accept
                depth += l.count("{") - l.count("}")
                i += 1

            # Merge if same resource type appears more than once in a file
            if block_type not in target:
                target[block_type] = {"arguments": sorted(args)}
            else:
                merged = set(target[block_type]["arguments"]) | args
                target[block_type]["arguments"] = sorted(merged)

            continue  # skip the i += 1 at the bottom

        i += 1

    return resources, data_sources


def find_tf_files(root):
    """Walk the repo and return sorted list of .tf file paths, skipping SKIP_DIRS."""
    tf_files = []
    for dirpath, dirnames, filenames in os.walk(root):
        # Prune unwanted directories in-place (affects os.walk descent)
        dirnames[:] = [
            d for d in dirnames
            if d not in SKIP_DIRS and not d.startswith(".")
        ]
        for filename in filenames:
            if filename.endswith(".tf"):
                tf_files.append(os.path.join(dirpath, filename))
    return sorted(tf_files)


def main():
    parser = argparse.ArgumentParser(
        description="Generate .iac-manifest.json from Terraform files"
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Root directory of the Terraform repo (default: current directory)",
    )
    args = parser.parse_args()

    root = os.path.abspath(args.root)
    output_path = os.path.join(root, ".iac-manifest.json")

    print(f"Root: {root}")

    version = get_azurerm_version(root)
    tf_files = find_tf_files(root)

    print(f"azurerm version : {version}")
    print(f"Found .tf files : {len(tf_files)}")
    print()

    manifest = {
        "last_checked_version": version,
        "last_checked_date": date.today().isoformat(),
        "files": {},
    }

    for tf_file in tf_files:
        rel_path = os.path.relpath(tf_file, root).replace("\\", "/")

        with open(tf_file, "r", encoding="utf-8") as f:
            content = f.read()

        file_hash = hash_file(tf_file)
        resources, data_sources = extract_blocks(content)

        # Only include files that actually contain resource or data blocks
        if resources or data_sources:
            manifest["files"][rel_path] = {
                "hash": file_hash,
                "resources": resources,
                "data_sources": data_sources,
            }
            print(
                f"  {rel_path}: "
                f"{len(resources)} resource(s), {len(data_sources)} data source(s)"
            )

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print()
    print(f"Manifest written : {output_path}")
    print(f"Files with blocks: {len(manifest['files'])}")


if __name__ == "__main__":
    main()
