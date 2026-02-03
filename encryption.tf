# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## Disk Encryption Resources
# This file manages Azure Key Vault, encryption keys, and Disk Encryption Sets
# for AKS nodes and VM disk encryption

# Data source to get current client configuration
data "azurerm_client_config" "current" {}

locals {
  # Determine if we should create encryption resources
  create_encryption_resources = var.create_disk_encryption_set
  
  # Use provided resource group or default to AKS resource group
  encryption_rg = var.disk_encryption_resource_group_name != null ? var.disk_encryption_resource_group_name : local.aks_rg.name
  
  # Generate names with prefix
  key_vault_name = var.key_vault_name != null ? var.key_vault_name : "${var.prefix}kv${random_id.kv_suffix[0].hex}"
  encryption_key_name = var.disk_encryption_key_name != null ? var.disk_encryption_key_name : "${var.prefix}-disk-encryption-key"
  disk_encryption_set_name = var.disk_encryption_set_name != null ? var.disk_encryption_set_name : "${var.prefix}-des"
  
  # Computed encryption set IDs
  computed_aks_encryption_set_id = local.create_encryption_resources ? azurerm_disk_encryption_set.des[0].id : var.aks_node_disk_encryption_set_id
  computed_vm_encryption_set_id = local.create_encryption_resources ? azurerm_disk_encryption_set.des[0].id : var.vm_disk_encryption_set_id
}

# Random suffix for Key Vault name (must be globally unique)
resource "random_id" "kv_suffix" {
  count       = local.create_encryption_resources ? 1 : 0
  byte_length = 4
}

# Azure Key Vault for encryption keys
resource "azurerm_key_vault" "encryption" {
  count                      = local.create_encryption_resources ? 1 : 0
  name                       = local.key_vault_name
  location                   = var.location
  resource_group_name        = local.encryption_rg
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  
  # Enable for disk encryption
  enabled_for_disk_encryption = true
  
  # Network rules - deny public access to comply with Azure Policy
  # Allow specific IPs for deployment and management
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.key_vault_allowed_cidrs
  }
  
  tags = merge(
    var.tags,
    {
      "Purpose" = "Disk Encryption"
    }
  )
}

# Access policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current" {
  count        = local.create_encryption_resources ? 1 : 0
  key_vault_id = azurerm_key_vault.encryption[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  
  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "GetRotationPolicy",
    "SetRotationPolicy",
  ]
}

# Encryption key in Key Vault
resource "azurerm_key_vault_key" "encryption" {
  count        = local.create_encryption_resources ? 1 : 0
  name         = local.encryption_key_name
  key_vault_id = azurerm_key_vault.encryption[0].id
  key_type     = var.disk_encryption_key_type
  key_size     = var.disk_encryption_key_size
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  
  # Ensure access policy is created first
  depends_on = [
    azurerm_key_vault_access_policy.current
  ]
  
  tags = merge(
    var.tags,
    {
      "Purpose" = "Disk Encryption"
    }
  )
}

# Disk Encryption Set
resource "azurerm_disk_encryption_set" "des" {
  count               = local.create_encryption_resources ? 1 : 0
  name                = local.disk_encryption_set_name
  resource_group_name = local.encryption_rg
  location            = var.location
  key_vault_key_id    = azurerm_key_vault_key.encryption[0].id
  
  # Encryption type
  encryption_type = var.disk_encryption_type
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = merge(
    var.tags,
    {
      "Purpose" = "Disk Encryption for AKS and VMs"
    }
  )
}

# Grant Disk Encryption Set access to Key Vault
resource "azurerm_key_vault_access_policy" "des" {
  count        = local.create_encryption_resources ? 1 : 0
  key_vault_id = azurerm_key_vault.encryption[0].id
  tenant_id    = azurerm_disk_encryption_set.des[0].identity[0].tenant_id
  object_id    = azurerm_disk_encryption_set.des[0].identity[0].principal_id
  
  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
  ]
  
  depends_on = [
    azurerm_disk_encryption_set.des
  ]
}
