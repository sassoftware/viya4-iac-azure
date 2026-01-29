# AI Agent Instructions for viya4-iac-azure

## Project Overview
This is a Terraform-based Infrastructure as Code (IaC) project for provisioning Azure resources for SAS Viya 4 deployments. It creates AKS clusters, networking, storage (NFS/NetApp), PostgreSQL databases, and container registries.

## Architecture Pattern
- **Root module** (`main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`) orchestrates child modules
- **Child modules** in `modules/` directory: `azure_aks`, `aks_node_pool`, `azurerm_vnet`, `azurerm_postgresql_flex`, `azurerm_netapp`, `azurerm_vm`, `kubeconfig`
- **Locals-first pattern**: Complex logic lives in `locals.tf` with conditional expressions (e.g., BYO resource detection, CIDR calculations, resource group selection)
- **Data sources** distinguish between creating new resources vs. using existing ones (pattern: `count = var.x == null ? 1 : 0`)

## Key Conventions

### Variable Naming
- Prefix-based naming: All Azure resources use `${var.prefix}-<resource-type>` naming pattern
- Public access control: `*_public_access_cidrs` variables control NSG rules, always default to `local.default_public_access_cidrs`
- "Community" prefix: Variables like `community_priority`, `community_eviction_policy` indicate community/non-enterprise features

### Conditional Resource Creation
- Use `count` for optional resources: `count = var.create_x ? 1 : 0`
- BYO (Bring Your Own) pattern: `var.x_name == null ? azurerm_x.new[0] : data.azurerm_x.existing[0]`
- Check `locals.tf` for how BYO resources are resolved (UAI, NSG, resource groups, VNets)

### Module Interface
- Node pools use `fips_enabled` flag but do NOT explicitly set OS image version (relies on Azure defaults)
- To force Ubuntu 22.04 for node pools: Add `os_sku` parameter to `azurerm_kubernetes_cluster_node_pool` resources in `modules/aks_node_pool/main.tf`
- Authentication: Three modes - local accounts, Entra+K8s RBAC, Entra+Azure RBAC (see `rbac_aad_*` variables)

## Testing Infrastructure

### Test Organization
- Tests use Terratest (Go) in `test/` directory
- **CRITICAL**: Tests use a shared cache keyed by `variables["prefix"]` in `test/helpers/plan_cache.go`
- **Always use unique prefixes** in parallel tests to prevent cache pollution (e.g., `variables["prefix"] = "testname"`)
- Test structure: `defaultplan/` (tests with defaults), `nondefaultplan/` (custom configs), `defaultapply/`, `nondefaultapply/`

### Running Tests
```bash
# Build and run all tests
make runTests

# Requires environment variables: TF_VAR_subscription_id, TF_VAR_tenant_id, TF_VAR_client_id, TF_VAR_client_secret
# Tests run in Docker container defined by Dockerfile.terratest
```

### Test Patterns
- Use `helpers.GetDefaultPlanVars(t)` to load from `examples/sample-input-defaults.tfvars`
- Set unique prefix: `variables["prefix"] = "uniquename"` before calling `helpers.GetPlan(t, variables)`
- Use `t.Parallel()` for concurrent execution but ensure unique cache keys

## Development Workflows

### Local Development (Docker - Recommended)
```bash
# See docs/user/DockerUsage.md
docker build -t viya4-iac-azure .
docker run -it --rm -v $(pwd):/workspace viya4-iac-azure
```

### Authentication Setup
Set environment variables (see `docs/user/TerraformAzureAuthentication.md`):
- `TF_VAR_subscription_id`, `TF_VAR_tenant_id`, `TF_VAR_client_id`, `TF_VAR_client_secret`
- Or use Azure VM Managed Identity: `TF_VAR_use_msi=true`

### Configuration Files
- Start from `examples/sample-input-*.tfvars` (minimal, defaults, ha, postgres, app-gateway, etc.)
- Copy to `terraform.tfvars` and customize
- All variables documented in `docs/CONFIG-VARS.md` with types, defaults, and notes

## Common Pitfalls

1. **Test cache collisions**: If tests fail with unexpected values, check for duplicate `prefix` values in parallel tests
2. **FIPS image versions**: Node pools with `fips_enabled = true` default to Ubuntu 20.04 unless explicitly set via `os_sku` or custom image
3. **Public access**: Omitting `default_public_access_cidrs` creates fully public resources (security risk)
4. **BYO resources**: When using existing resources (e.g., `vnet_resource_group_name`), ensure proper permissions and naming
5. **NetApp storage**: Only created when `storage_type = "ha"` (see `locals.subnets` conditional logic)

## File Reference
- **Variable defaults**: `variables.tf` (933 lines) - check here first for default values
- **Resource composition logic**: `locals.tf` - complex conditionals for CIDR, BYO detection
- **Main orchestration**: `main.tf` (304 lines) - provider config, resource groups, module calls
- **Test cache**: `test/helpers/plan_cache.go` - understand cache keying to avoid test issues
- **Configuration docs**: `docs/CONFIG-VARS.md` - comprehensive variable reference with examples
