# SAS Viya 4 Infrastructure as Code (IaC) for Azure - AI Coding Guide

## Project Overview
This is a Terraform-based Infrastructure as Code project that provisions Azure resources for SAS Viya 4 platform deployment. The primary goal is to automate the cluster-provisioning phase before SAS Viya platform deployment.

## Architecture & Key Components

### Core Infrastructure
- **AKS Cluster**: Managed Kubernetes cluster with system and user node pools
- **Networking**: VNet, subnets, NSGs with configurable public/private access
- **Storage**: NFS Server (standard) or Azure NetApp Files (HA) options
- **Database**: Optional Azure PostgreSQL Flexible Server
- **Registry**: Optional Azure Container Registry (ACR)

### Module Structure
- `modules/azure_aks/`: Core AKS cluster provisioning
- `modules/aks_node_pool/`: Additional node pool management
- `modules/azurerm_vnet/`: Virtual network infrastructure
- `modules/azurerm_vm/`: Jump server and NFS VM provisioning
- `modules/azurerm_postgresql_flex/`: PostgreSQL database setup
- `modules/azurerm_netapp/`: Azure NetApp Files for HA storage

## Development Patterns

### Variable Configuration
- **Required vars**: `prefix`, `location`, plus Azure auth (`subscription_id`, `tenant_id`)
- **Configuration files**: Use `terraform.tfvars` or example files in `examples/`
- **Locals pattern**: Complex logic in `locals.tf` (CIDR calculations, conditional resources)
- **Variable validation**: Extensive validation rules in `variables.tf` (876 lines)

### Testing Framework (Terratest)
- **Structure**: `test/defaultplan/` (plan validation) vs `test/defaultapply/` (real resources)
- **Helper pattern**: `test/helpers/` contains reusable test utilities
- **TestCase struct**: Standardized test cases with JSON path validation
- **Parallel execution**: Tests use `t.Parallel()` for faster execution

### Docker Development
- **Preferred method**: Use Docker container with pre-installed tools
- **Image**: Built with Terraform 1.10.5, Azure CLI 2.70.0, kubectl 1.32.6
- **Commands**: `make runTests` for full test suite, `make buildTests` for image build
- **Environment**: Requires Azure auth env vars (`TF_VAR_*`)

## Critical Workflows

### Testing
```bash
# Plan validation tests (fast, no real resources)
go test ./test/defaultplan/...

# Apply tests (slow, creates real Azure resources)
go test ./test/defaultapply/...

# Using Docker (recommended)
make runTests
```

### Terraform Operations
```bash
# Using Docker container
docker run -it --rm -v $(pwd):/workspace viya4-iac-azure:latest

# Direct Terraform (requires local tools)
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Project-Specific Conventions

### Resource Naming
- **Prefix-based**: All resources use `var.prefix` for consistent naming
- **Pattern**: `${var.prefix}-rg`, `${var.prefix}-aks`, etc.
- **Location suffix**: Often includes Azure location in names

### Configuration Patterns
- **Conditional resources**: Use `count = condition ? 1 : 0` pattern extensively
- **Complex types**: Heavy use of `object()` types for node pools, postgres configs
- **Default merging**: `merge(defaults, user_config)` pattern for complex objects

### Authentication Options
- **Service Principal**: Default method with client_id/client_secret
- **Managed Identity**: For Azure VMs (`use_msi = true`)
- **Environment variables**: Preferred for sensitive auth data

### Storage Configuration
- **Standard mode**: Creates NFS VM with managed disk
- **HA mode**: Uses Azure NetApp Files
- **Selection**: Controlled by `storage_type` variable

## Integration Points

### External Dependencies
- **Azure Provider**: Requires specific azurerm/azuread provider versions
- **Kubernetes Provider**: Auto-configured from AKS cluster outputs
- **SAS Viya Deployment**: Outputs kubeconfig for next deployment phase

### Cross-Module Communication
- **Module outputs**: Well-defined outputs for cluster, network, storage info
- **Data sources**: Extensive use of `data` blocks for existing resources
- **Local values**: `locals.tf` centralizes complex calculations

## Testing Validation Patterns
- **JSON Path**: Use `{$.path.to.attribute}` for nested resource validation
- **Plan vs Apply**: Plan tests validate configuration, apply tests verify actual resources
- **Parallel execution**: Most tests can run in parallel except apply tests