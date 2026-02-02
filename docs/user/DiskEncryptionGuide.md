# Disk Encryption Configuration Guide

This guide explains how to configure disk encryption for AKS nodes and VMs in the viya4-iac-azure project.

## Overview

The project supports three approaches for disk encryption:

1. **Automatic Creation** (Recommended): Terraform creates all encryption resources
2. **Bring Your Own** (BYO): Use existing Disk Encryption Sets
3. **Opt-Out** (Dev/Test Only): Temporarily disable enforcement

## Option 1: Automatic Encryption Resource Creation (Recommended)

Terraform will automatically create:
- Azure Key Vault
- Encryption Key (RSA 4096-bit by default)
- Disk Encryption Set
- Required access policies

### Basic Configuration

```hcl
# terraform.tfvars
prefix          = "viya4"
location        = "eastus"
subscription_id = "your-subscription-id"
tenant_id       = "your-tenant-id"

# Enable automatic creation
create_disk_encryption_set = true
```

That's it! Encryption enforcement is enabled by default.

### Advanced Configuration

#### FIPS 140-2 Level 3 Compliance

For FIPS compliance with HSM-backed keys:

```hcl
create_disk_encryption_set = true
key_vault_sku              = "premium"       # Premium SKU for HSM
disk_encryption_key_type   = "RSA-HSM"       # HSM-backed key
disk_encryption_key_size   = 4096
```

#### Double Encryption

For enhanced security with both platform-managed and customer-managed keys:

```hcl
create_disk_encryption_set = true
disk_encryption_type       = "EncryptionAtRestWithPlatformAndCustomerKeys"
```

#### Custom Names

```hcl
create_disk_encryption_set = true
key_vault_name             = "mycustom-kv-001"
disk_encryption_key_name   = "my-encryption-key"
disk_encryption_set_name   = "my-des"
```

#### Separate Resource Group

```hcl
create_disk_encryption_set              = true
disk_encryption_resource_group_name     = "encryption-resources-rg"
```

## Option 2: Bring Your Own Disk Encryption Set

If you already have a Disk Encryption Set:

```hcl
# Disable auto-creation
create_disk_encryption_set = false

# Provide existing resource IDs
aks_node_disk_encryption_set_id = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Compute/diskEncryptionSets/{des-name}"
vm_disk_encryption_set_id       = "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Compute/diskEncryptionSets/{des-name}"

# Enforcement remains enabled by default
enforce_aks_node_disk_encryption = true
enforce_vm_disk_encryption       = true
```

You can use:
- Same Disk Encryption Set for both AKS and VMs
- Different Disk Encryption Sets for each

## Option 3: Temporary Opt-Out (Not Recommended for Production)

For development, testing, or migration scenarios:

```hcl
# Disable auto-creation
create_disk_encryption_set = false

# Disable enforcement temporarily
enforce_aks_node_disk_encryption = false
enforce_vm_disk_encryption       = false
```

⚠️ **Warning**: This disables encryption enforcement and should only be used temporarily.

## Additional Encryption Options

### Host-Level Encryption

For additional encryption at the host level:

```hcl
# For AKS nodes
aks_cluster_enable_host_encryption = true

# For Jump and NFS VMs
enable_vm_host_encryption = true
```

**Note**: Host encryption requires VM SKUs that support it. See [Azure documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/disk-encryption).

## Terraform Outputs

After deployment, useful outputs are available:

```bash
# Get Key Vault URI
terraform output key_vault_uri

# Get Disk Encryption Set ID
terraform output disk_encryption_set_id

# Get DES Managed Identity (for troubleshooting)
terraform output disk_encryption_set_identity
```

## Pre-requisites

### Azure Permissions

The Terraform service principal or user needs:
- `Contributor` role on the resource group
- `Key Vault Contributor` role (if creating Key Vault)
- Ability to assign access policies to Key Vault

### Region Requirements

- Key Vault, Disk Encryption Set, and AKS cluster must be in the **same Azure region**
- Check region availability for encryption features

## Manual Creation (Alternative to Terraform Automation)

If you prefer manual creation via Azure Portal or CLI, see the detailed steps in the main documentation.

### Azure Portal Quick Steps:
1. Create Key Vault with disk encryption enabled
2. Create encryption key (RSA 2048/4096)
3. Create Disk Encryption Set
4. Grant DES access to Key Vault
5. Copy Resource ID and add to tfvars

### Azure CLI:
```bash
# See complete CLI commands in the main documentation
az disk-encryption-set create --name my-des ...
```

## Migration Strategy

### Gradual Rollout

**Week 1**: Deploy with opt-out for testing
```hcl
enforce_aks_node_disk_encryption = false
enforce_vm_disk_encryption       = false
```

**Weeks 2-8**: Enable enforcement in stages
```hcl
# Enable for VMs first
enforce_vm_disk_encryption = true
enforce_aks_node_disk_encryption = false

# Then enable for AKS after validation
enforce_aks_node_disk_encryption = true
```

**Q3 2026**: Remove opt-out option entirely (mandatory encryption)

## Troubleshooting

### Common Issues

**Error: "Access Denied" when creating Disk Encryption Set**
- Solution: Ensure Key Vault access policies are configured
- The Disk Encryption Set's managed identity needs `Get`, `WrapKey`, `UnwrapKey` permissions

**Error: "Key Vault and Disk Encryption Set must be in same region"**
- Solution: Verify `location` variable matches for all resources

**Error: "Validation failed" for encryption set ID**
- Solution: Ensure ID format is correct: `/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/diskEncryptionSets/{name}`

### Validation

Check if encryption is working:

```bash
# For AKS nodes
az aks show --resource-group <rg> --name <cluster> --query "diskEncryptionSetId"

# For VMs
az vm show --resource-group <rg> --name <vm> --query "storageProfile.osDisk.managedDisk.diskEncryptionSet.id"
```

## Security Best Practices

1. ✅ **Use automatic creation** for consistent configuration
2. ✅ **Enable purge protection** on Key Vault (enabled by default)
3. ✅ **Use Premium SKU** for FIPS compliance requirements
4. ✅ **Use 4096-bit keys** for enhanced security
5. ✅ **Enable soft delete** for key recovery (enabled by default)
6. ✅ **Monitor Key Vault access** logs
7. ✅ **Rotate keys periodically** (manual process)
8. ⚠️ **Never commit** encryption keys or Key Vault credentials to git

## Performance Impact

- Encryption overhead: 2-5% (typically < 3%)
- Offset by Accelerated Networking (enabled by default)
- No noticeable impact on most workloads

## Cost Considerations

- Key Vault Standard: ~$0.03/10,000 operations
- Key Vault Premium: ~$1/key/month + operations
- Disk Encryption Set: No additional charge
- Encrypted disks: Same price as unencrypted

## Examples

See `examples/` directory for complete configurations:
- `sample-input-auto-encryption.tfvars` - Automatic creation with all options
- `sample-input-defaults.tfvars` - Default configuration with BYO encryption

## References

- [Azure Disk Encryption Documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/disk-encryption)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [AKS Encryption at Host](https://learn.microsoft.com/en-us/azure/aks/enable-host-encryption)
- [FIPS 140-2 Validation](https://csrc.nist.gov/projects/cryptographic-module-validation-program)
