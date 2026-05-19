# Copilot Instructions — IaC Deprecation Agent

## Project Purpose
This toolset detects breaking changes and deprecations in the `azurerm` Terraform provider for a given IaC repo (currently targeting `viya4-iac-azure`). It operates in two stages: manifest generation → deprecation check.

## Architecture & Data Flow

```
[Target IaC repo] → generate_manifest.py → .iac-manifest.json
                                                     ↓
                    check_deprecations.py ← Terraform Registry API (latest version)
                                         ← azurerm CHANGELOG (GitHub raw)
                                                     ↓
                                           deprecation-report.json
```

### Key Files
- `.github/tools/manifest/generate_manifest.py` — Scans `.tf` files, extracts `resource`/`data` block types and top-level arguments, writes `.iac-manifest.json` into the target repo root.
- `tools/manifest/check_deprecations.py` — Reads `.iac-manifest.json`, fetches the CHANGELOG delta between current and latest `azurerm` versions, cross-references resource types, and writes `deprecation-report.json`.
- `deprecation-report.json` — Output artifact consumed by agents or CI; contains `summary` (counts by severity) and `affected_resources` (per-resource changelog lines + file paths).

## Workflow — Run Order Matters

```bash
# Step 1: Generate manifest (run against the target IaC repo)
python .github/tools/manifest/generate_manifest.py --root /path/to/iac-repo

# Step 2: Check deprecations (also run from or pointed at that repo root)
python tools/manifest/check_deprecations.py --root /path/to/iac-repo
```

- Both scripts default `--root` to `.` (current directory = target IaC repo root).
- `check_deprecations.py` will **exit with an error** if `.iac-manifest.json` is missing — always run `generate_manifest.py` first.
- No external pip packages needed — Python 3.6+ stdlib only.

## Severity Model

| Severity | Meaning | Action |
|---|---|---|
| `BREAKING` | Argument removed or renamed in changelog range | Fix `.tf` files **before** bumping `azurerm` version |
| `DEPRECATED` | Explicitly deprecated; still functional | Plan migration before next major release |
| `CHANGED` | Behaviour/bug-fix change | Review before upgrading |

Severity is assigned per resource type by `classify_severity()` in `check_deprecations.py`. A rename pattern (`has been renamed to`) always escalates to `BREAKING`.

## Manifest Schema (`.iac-manifest.json`)

```json
{
  "last_checked_version": "4.48.0",
  "last_checked_date": "2026-05-19",
  "files": {
    "modules/azure_aks/main.tf": {
      "hash": "<sha256>",
      "resources": { "azurerm_kubernetes_cluster": { "arguments": ["dns_prefix", ...] } },
      "data_sources": {}
    }
  }
}
```

- Only `.tf` files containing `resource` or `data` blocks are included.
- Skipped directories: `test`, `examples`, `.terraform`, `.git`, `.github`.
- `azurerm` provider version is read from `versions.tf` in the repo root.

## Report Schema (`deprecation-report.json`)

- `summary.status`: `UP_TO_DATE` or `REVIEW_REQUIRED`
- `affected_resources[].severity`: one of `BREAKING`, `DEPRECATED`, `CHANGED`
- `affected_resources[].files`: list of `.tf` file paths from the manifest
- `affected_resources[].lifecycle_note`: human-readable upgrade note (may be `null`)

## External Dependencies

- **Terraform Registry API**: `https://registry.terraform.io/v1/providers/hashicorp/azurerm` — used to resolve `latest_version`.
- **azurerm CHANGELOG**: `https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/CHANGELOG.md` — parsed with regex to isolate the delta between `current_version` and `latest_version`.

Both calls use `urllib` with a 30-second timeout; network failures raise `SystemExit(1)` with a clear message.
