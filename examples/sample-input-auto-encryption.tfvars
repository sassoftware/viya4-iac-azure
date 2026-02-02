# Sample input file for disk encryption with automated creation
# This example demonstrates automatic creation of encryption resources

## Required variables
prefix          = "viya4enc"
location        = "eastus"
subscription_id = "12345678-1234-1234-1234-123456789abc"
tenant_id       = "87654321-4321-4321-4321-cba987654321"

## OPTION 1: Automatic Encryption Resource Creation (Recommended)
# Terraform will create Key Vault, encryption key, and Disk Encryption Set
create_disk_encryption_set = true

# Optional: Customize encryption resources
# key_vault_name             = "viya-kv-custom"        # Leave null for auto-generated name
# key_vault_sku              = "premium"               # Use 'premium' for HSM-backed keys (FIPS 140-2 Level 3)
# disk_encryption_key_name   = "custom-key"            # Leave null for auto-generated name
# disk_encryption_key_type   = "RSA-HSM"               # Use 'RSA-HSM' for FIPS compliance with premium SKU
# disk_encryption_key_size   = 4096                    # 2048, 3072, or 4096
# disk_encryption_set_name   = "custom-des"            # Leave null for auto-generated name
# disk_encryption_type       = "EncryptionAtRestWithPlatformAndCustomerKeys"  # Double encryption

# Enforcement is enabled by default (secure by default)
# enforce_aks_node_disk_encryption = true
# enforce_vm_disk_encryption       = true

# Optional: Additional encryption at host level
# aks_cluster_enable_host_encryption = true
# enable_vm_host_encryption          = true

## OPTION 2: Use Existing Disk Encryption Set
# If you already have a Disk Encryption Set, disable auto-creation and provide IDs
# create_disk_encryption_set       = false
# enforce_aks_node_disk_encryption = true
# aks_node_disk_encryption_set_id  = "/subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/encryption-rg/providers/Microsoft.Compute/diskEncryptionSets/viya-des"
# enforce_vm_disk_encryption       = true
# vm_disk_encryption_set_id        = "/subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/encryption-rg/providers/Microsoft.Compute/diskEncryptionSets/viya-des"

## OPTION 3: Temporarily Disable Enforcement (Dev/Test Only - Not Recommended)
# Use this only for migration or development environments
# create_disk_encryption_set       = false
# enforce_aks_node_disk_encryption = false
# enforce_vm_disk_encryption       = false

## Other required settings
kubernetes_version = "1.33"
