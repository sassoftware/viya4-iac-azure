# Copilot Instructions for viya4-iac-azure

This is a **Terraform Infrastructure-as-Code project** that provisions Azure cloud resources for SAS Viya 4 platform deployment.

## Project Overview

- **Purpose**: Automate provisioning of Azure Kubernetes Service (AKS) clusters and supporting infrastructure for SAS Viya 4 deployments
- **Core Technology**: Terraform v1.10+ with Azure providers (azurerm v4.57, azuread v3.1, kubernetes v2.36)
- **Key Outputs**: Managed AKS cluster, virtual networks, node pools, storage (NFS/NetApp), PostgreSQL, container registry, and kubeconfig

## Architecture & Key Components

### Root-Level Modules (in `/modules`)
- **`azure_aks`**: Configures the AKS cluster with network profiles, RBAC, and workload identity
- **`aks_node_pool`**: Creates system and user node pools with custom labels/taints
- **`azurerm_vnet`**: Provisions VNet and subnets (aks, control_plane_subnet, netapp, etc.)
- **`azurerm_vm`**: Jump VM provisioning (optional bastion host)
- **`azurerm_postgresql_flex`**: Azure Database for PostgreSQL Flexible Server
- **`azurerm_netapp`**: Azure NetApp Files for HA storage (alternative to NFS)
- **`kubeconfig`**: Extracts and manages kubeconfig from AKS cluster

### Configuration Pattern
1. **variables.tf**: 900+ lines defining all input variables with validation rules
2. **locals.tf**: Computed values (e.g., CIDR calculations, conditional logic for BYO resources)
3. **main.tf**: Provider config, data sources for BYO resources (Resource Groups, VNets, NSGs, UAIs)
4. **{iam,monitor,vms}.tf**: Feature-specific resources (IAM, monitoring, virtual machines)

### Data Flow
1. User provides `terraform.tfvars` with infrastructure parameters
2. Terraform validates inputs and resolves conditionals via locals (e.g., create or BYO resource groups)
3. Modules instantiate Azure resources using computed CIDR ranges, tags, and identity settings
4. Kubeconfig is extracted and written to `[prefix]-aks-kubeconfig.conf`

## Critical Terraform Variables & Conventions

### Mandatory Variables
- `subscription_id`, `tenant_id`: Azure authentication
- `prefix` (3-20 chars, lowercase, no leading/trailing hyphens): Used in naming all resources
- `location`: Azure region (default: "eastus")

### Authentication Patterns (see [TerraformAzureAuthentication.md](docs/user/TerraformAzureAuthentication.md))
- **Service Principal**: Set `TF_VAR_client_id`, `TF_VAR_client_secret` environment variables
- **MSI**: Set `var.use_msi = true` for Azure VM deployments with managed identity
- **Provider**: Uses `azurerm`, `azuread`, and `kubernetes` providers configured in main.tf

### BYO Resource Pattern (Conditional Creation)
Many resources support "Bring Your Own" (BYO) to reuse existing Azure assets:
- `var.resource_group_name` → data source if provided, else create new RG
- `var.vnet_resource_group_name` → reuse VNet in different RG
- `var.aks_uai_name` → reuse existing User Assigned Identity
- Logic: `count = var.resource_name == null ? 1 : 0` for creation, `data.*` for existing

### CIDR/Network Conventions
- Computed in locals.tf using conditional coalescing (locals line 11-14)
- Example: `vm_public_access_cidrs = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : ...`
- Postgres firewall rules: Generated from CIDR lists using `cidrhost()` function

### Feature Flags
- `cluster_egress_type`: Controls outbound traffic (loadBalancer vs userDefinedRouting)
- `storage_type`: "standard" (NFS) or "premium" (NetApp)
- `enable_ipv6`: Dual-stack networking (IPv4+IPv6) - requires provider v4.57+
- `enable_workload_identity`: Enables OIDC-based workload identity for pod-to-Azure auth

## Testing & Validation

### Terratest Framework
- **Language**: Go 1.23
- **Structure**: Tests in `/test` with subdirs: `defaultplan/`, `defaultapply/`, `nondefaultplan/`, `nondefaultapply/`
- **Helper Functions**: `/test/helpers/` provides utilities (test case builder, JSON path navigation, terraform output parsing)
- **Key Test Files**:
  - `defaultplan/*.go`: Validates terraform plan output (e.g., defaults_test.go for variable defaults)
  - `defaultapply/*.go`: Post-apply validation (resource_group_test.go, vm_test.go, etc.)
- **Run Tests**: `make runTests` (requires Docker, TF_VAR_* credentials set)

### Test Execution
```bash
# Build test container and run tests
make runTests

# Environment: Tests run inside Docker container (viya4-iac-azure:terratest)
# Credentials passed via: TF_VAR_subscription_id, TF_VAR_tenant_id, TF_VAR_client_id, TF_VAR_client_secret
```

## Common Developer Workflows

### Initialize & Plan
```bash
# Set credentials (see TerraformAzureAuthentication.md)
export TF_VAR_subscription_id="..."
export TF_VAR_tenant_id="..."
export TF_VAR_client_id="..."
export TF_VAR_client_secret="..."

# Copy example config
cp examples/sample-input.tfvars terraform.tfvars

# Initialize Terraform
terraform init

# Preview infrastructure
terraform plan
```

### Apply & Destroy
```bash
terraform apply -auto-approve
terraform output  # Display outputs (kubeconfig, IPs, credentials)
terraform destroy  # Tear down (irreversible)
```

### Docker Alternative (Recommended)
- See [DockerUsage.md](docs/user/DockerUsage.md)
- Docker image includes all prerequisites (terraform, kubectl, jq, Azure CLI)
- Entrypoint: [docker-entrypoint.sh](docker-entrypoint.sh)

## Important Patterns & Conventions

### Variable Validation
- **Prefix validation**: Regex `^[a-z][-0-9a-z]*[0-9a-z]$` with length 3-20 (variables.tf:41-47)
- **Custom validation blocks**: Use `validation {}` for complex constraints
- **Error messages**: Provide clear guidance in validation error_message field

### Locals Usage
- **Complex conditionals**: AKS UAI selection (locals.tf:61-72) shows three-level ternary for BYO logic
- **Conditional subnet inclusion**: `for` expression filters netapp subnet based on storage_type (locals.tf:16)
- **CIDR calculations**: Use `cidrhost()` to generate firewall rule IP ranges from CIDR notation

### Resource Naming
- All resources prefixed with `var.prefix` to ensure global uniqueness
- Naming convention: `${var.prefix}-[resource-type]-[descriptor]`
- Example: `${var.prefix}-rg`, `${var.prefix}-aks-kubeconfig.conf`

### Tags & Metadata
- `var.tags`: Applied to taggable resources
- `var.iac_tooling`: Track whether infrastructure created by "terraform" or "docker" (partner_id integration)

### Sensitive Variables
- Outputs marked `sensitive = true`: kubeconfig, credentials, certificates (outputs.tf)
- Secret handling: Variables like client_secret stored as `default = ""` (never hardcode credentials)

## Documentation Reference

- **[CONFIG-VARS.md](docs/CONFIG-VARS.md)**: Detailed variable definitions and dependencies
- **[TerraformAzureAuthentication.md](docs/user/TerraformAzureAuthentication.md)**: Auth setup (Service Principal, MSI, CLI)
- **[TerraformUsage.md](docs/user/TerraformUsage.md)**: Basic terraform CLI workflow
- **[AdvancedTerraformUsage.md](docs/user/AdvancedTerraformUsage.md)**: Variable files, state management
- **[BYOnetwork.md](docs/user/BYOnetwork.md)**: Using existing VNets and subnets
- **[TestingPhilosophy.md](docs/user/TestingPhilosophy.md)**: Terratest rationale and approach

## Key Files for Common Tasks

| Task | File(s) |
|------|---------|
| Add Azure resource | modules/[module_name]/main.tf, variables.tf (add inputs) |
| Change default values | variables.tf (update defaults), examples/*.tfvars (update examples) |
| Modify AKS config | modules/azure_aks/main.tf |
| Add node pool | modules/aks_node_pool/*, aks_node_pool.tf |
| Update tests | test/{defaultplan,defaultapply}/*, test/helpers/* |
| Enable new feature | variables.tf (add toggle), locals.tf (compute logic), main.tf (reference) |

## Version Constraints

- **Terraform**: >= 1.10.0 (versions.tf)
- **AzureRM Provider**: = 4.57.0 (pinned, IPv6 dual-stack support)
- **Go**: 1.23.2 (test/go.mod)
- **Kubernetes**: v1.32.6 required by AKS (README.md)

## Release & Compatibility

- **Versioning**: SemVer (MAJOR.MINOR.PATCH)
- **Backward Compatibility**: MAJOR version bumps may require infrastructure rebuild
- **Partner ID**: `5d27f3ae-e49c-4dea-9aa3-b44e4750cd8c` (Microsoft partner attribution)

---

**Last Updated**: January 2026  
For questions about infrastructure design or module architecture, review the architecture diagram in [docs/images/viya4-iac-azure-diag.png](docs/images/viya4-iac-azure-diag.png).
