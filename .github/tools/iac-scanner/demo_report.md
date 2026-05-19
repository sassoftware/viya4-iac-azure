# 🔍 IaC Deprecation Scan Report

**Repository:** `C:\Users\lodave\viya4-iac-azure`
**Scan Date:** 2026-05-19 15:31:48
**Duration:** 0.22s

---

## Summary

| Metric | Value |
|--------|-------|
| Files Scanned | 66 |
| Total Issues | 12 |
| 🔴 Critical | 1 |
| 🟠 High | 7 |
| 🟡 Medium | 3 |
| 🔵 Low | 1 |
| ⚪ Info | 0 |

## 🔴 CRITICAL (1)

### Deprecated azurerm provider version 1.x

- **Location:** `versions.tf:6`
- **Category:** terraform
- **Description:** azurerm provider version 1.x is end-of-life and no longer maintained.
- **Recommended:** `~> 4.0`
- **Fix:** Update provider version constraint to ~> 4.0 and follow migration guide.
- **Documentation:** [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)

## 🟠 HIGH (7)

### Hardcoded credentials pattern

- **Location:** `.github\workflows\default_plan_unit_tests.yml:33`
- **Category:** general
- **Description:** Potential hardcoded password or API key detected.
- **Fix:** Use environment variables, secret management, or Terraform variables for sensitive values.

### Hardcoded credentials pattern

- **Location:** `files\tools\terraform_env_variable_helper.sh:49`
- **Category:** general
- **Description:** Potential hardcoded password or API key detected.
- **Fix:** Use environment variables, secret management, or Terraform variables for sensitive values.

### Hardcoded credentials pattern

- **Location:** `variables.tf:347`
- **Category:** general
- **Description:** Potential hardcoded password or API key detected.
- **Fix:** Use environment variables, secret management, or Terraform variables for sensitive values.

### Deprecated azurerm provider version 2.x

- **Location:** `versions.tf:19`
- **Category:** terraform
- **Description:** azurerm provider version 2.x is deprecated and will not receive updates.
- **Recommended:** `~> 4.0`
- **Fix:** Update provider version constraint to ~> 4.0 and follow migration guide.
- **Documentation:** [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)

### Deprecated azurerm provider version 2.x

- **Location:** `versions.tf:23`
- **Category:** terraform
- **Description:** azurerm provider version 2.x is deprecated and will not receive updates.
- **Recommended:** `~> 4.0`
- **Fix:** Update provider version constraint to ~> 4.0 and follow migration guide.
- **Documentation:** [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)

### Deprecated azurerm provider version 2.x

- **Location:** `versions.tf:35`
- **Category:** terraform
- **Description:** azurerm provider version 2.x is deprecated and will not receive updates.
- **Recommended:** `~> 4.0`
- **Fix:** Update provider version constraint to ~> 4.0 and follow migration guide.
- **Documentation:** [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)

### Deprecated azurerm provider version 2.x

- **Location:** `versions.tf:39`
- **Category:** terraform
- **Description:** azurerm provider version 2.x is deprecated and will not receive updates.
- **Recommended:** `~> 4.0`
- **Fix:** Update provider version constraint to ~> 4.0 and follow migration guide.
- **Documentation:** [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)

## 🟡 MEDIUM (3)

### Deprecated GitHub Action: actions/checkout@v2

- **Location:** `.github\workflows\semvar.yml:14`
- **Category:** github-actions
- **Description:** The action actions/checkout@v2 uses a deprecated Node.js runtime or is outdated.
- **Current:** `actions/checkout@v2`
- **Recommended:** `actions/checkout@v4`
- **Fix:** Update from actions/checkout@v2 to actions/checkout@v4.
- **Documentation:** [https://github.blog/changelog/2023-09-22-github-actions-transitioning-from-node-16-to-node-20/](https://github.blog/changelog/2023-09-22-github-actions-transitioning-from-node-16-to-node-20/)

### Deprecated azurerm provider version 3.x

- **Location:** `versions.tf:15`
- **Category:** terraform
- **Description:** azurerm provider version 3.x is deprecated. Migration to 4.x is recommended.
- **Recommended:** `~> 4.0`
- **Fix:** Plan migration to azurerm 4.x. Review breaking changes in upgrade guide.
- **Documentation:** [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)

### Deprecated azurerm provider version 3.x

- **Location:** `versions.tf:27`
- **Category:** terraform
- **Description:** azurerm provider version 3.x is deprecated. Migration to 4.x is recommended.
- **Recommended:** `~> 4.0`
- **Fix:** Plan migration to azurerm 4.x. Review breaking changes in upgrade guide.
- **Documentation:** [https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)

## 🔵 LOW (1)

### Deprecated GitHub Action: actions/cache@v3

- **Location:** `.github\workflows\linter-analysis.yml:45`
- **Category:** github-actions
- **Description:** The action actions/cache@v3 uses a deprecated Node.js runtime or is outdated.
- **Current:** `actions/cache@v3`
- **Recommended:** `actions/cache@v4`
- **Fix:** Update from actions/cache@v3 to actions/cache@v4.
- **Documentation:** [https://github.blog/changelog/2023-09-22-github-actions-transitioning-from-node-16-to-node-20/](https://github.blog/changelog/2023-09-22-github-actions-transitioning-from-node-16-to-node-20/)

---

*Generated by IaC Deprecation Scanner v1.0.0*
