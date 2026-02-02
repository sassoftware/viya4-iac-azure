# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
# MULTI-AZ ENHANCED VERSION - Compare with main.tf
# This version adds cross-zone replication for true zone failure resilience

# Validation: Ensure zones differ when cross-zone replication is enabled

# Terraform docs - https://www.terraform.io/docs/providers/azurerm/r/netapp_volume.html
# Terraform Registry - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/netapp_volume
# Azure docs - https://docs.microsoft.com/en-us/azure/azure-netapp-files/
# Multi-zone docs - https://learn.microsoft.com/en-us/azure/reliability/reliability-netapp-files
# Cross-zone replication - https://learn.microsoft.com/en-us/azure/azure-netapp-files/create-cross-zone-replication

resource "azurerm_netapp_account" "anf" {
  name                = "${var.prefix}-netappaccount"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Primary capacity pool for primary volume
resource "azurerm_netapp_pool" "anf" {
  name                = "${var.prefix}-netapppool"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf.name
  service_level       = var.service_level
  size_in_tb          = var.size_in_tb
  tags                = var.tags
}

# Separate capacity pool for replica volume (required for cross-zone replication)
resource "azurerm_netapp_pool" "anf_replica" {
  count = var.netapp_enable_cross_zone_replication ? 1 : 0
  
  name                = "${var.prefix}-netapppool-replica"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf.name
  service_level       = var.service_level
  size_in_tb          = var.size_in_tb
  tags                = merge(var.tags, { "role" = "replica" })
}

# Primary NetApp Volume
resource "azurerm_netapp_volume" "anf" {
  name                = "${var.prefix}-netappvolume"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf.name
  service_level       = var.service_level
  pool_name           = "${var.prefix}-netapppool"
  volume_path         = var.volume_path
  subnet_id           = var.subnet_id
  network_features    = var.network_features
  protocols           = var.protocols
  storage_quota_in_gb = var.community_netapp_volume_size == 0 ? var.size_in_tb * 1024 : var.community_netapp_volume_size
  tags                = merge(var.tags, { "role" = "primary" })#error
  
  # Set availability zone for primary volume
  zone                = var.netapp_availability_zone

  export_policy_rule {
    rule_index          = 1
    allowed_clients     = var.allowed_clients
    protocol           = var.protocols
    unix_read_write     = true
    root_access_enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    azurerm_netapp_pool.anf
  ]
}

# Replica Volume for Cross-Zone Replication
resource "azurerm_netapp_volume" "anf_replica" {
  count = var.netapp_enable_cross_zone_replication ? 1 : 0
  
  name                = "${var.prefix}-netappvolume-replica"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf.name
  service_level       = var.service_level
  pool_name           = "${var.prefix}-netapppool-replica"
  # CRITICAL: Use SAME volume_path as primary to ensure identical export paths
  # This allows StorageClass to mount using same path after DNS failover
  volume_path         = var.volume_path  # Changed from "${var.volume_path}-replica"
  subnet_id           = var.subnet_id
  network_features    = var.network_features
  protocols           = var.protocols
  storage_quota_in_gb = var.community_netapp_volume_size == 0 ? var.size_in_tb * 1024 : var.community_netapp_volume_size
  tags                = merge(var.tags, { "role" = "replica" })
  
  # Different zone for high availability
  zone                = var.netapp_replication_zone

  # Configure as replication destination
  data_protection_replication {
    endpoint_type             = "dst"
    remote_volume_location    = var.location
    remote_volume_resource_id = azurerm_netapp_volume.anf.id
    replication_frequency     = var.netapp_replication_frequency
  }

  export_policy_rule {
    rule_index          = 1
    allowed_clients     = var.allowed_clients
    protocol           = var.protocols
    unix_read_write     = true
    root_access_enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    azurerm_netapp_pool.anf_replica,
    azurerm_netapp_volume.anf
  ]
}

# Private DNS Zone for Cross-Zone Replication resilience
# Creates a stable hostname that can be updated during ANF failover
resource "azurerm_private_dns_zone" "anf_dns" {
  count = var.netapp_enable_cross_zone_replication ? 1 : 0

  name                = var.netapp_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, { "purpose" = "anf-czr-resilience" })
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "anf_dns_link" {
  count = var.netapp_enable_cross_zone_replication ? 1 : 0

  name                  = "${var.prefix}-anf-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.anf_dns[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags

  depends_on = [azurerm_private_dns_zone.anf_dns]
}

# DNS A Record pointing to primary ANF volume
# This record should be updated to the new primary IP during failover
resource "azurerm_private_dns_a_record" "anf_primary" {
  count = var.netapp_enable_cross_zone_replication ? 1 : 0

  name                = var.netapp_dns_record_name
  zone_name           = azurerm_private_dns_zone.anf_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_netapp_volume.anf.mount_ip_addresses[0]]
  tags                = merge(var.tags, { "role" = "primary-endpoint" })

  depends_on = [azurerm_private_dns_zone.anf_dns]
}

# Output replica information for monitoring
output "replica_volume_id" {
  description = "The ID of the replica NetApp volume (if cross-zone replication is enabled)"
  value       = var.netapp_enable_cross_zone_replication ? azurerm_netapp_volume.anf_replica[0].id : null
}

output "replica_mount_ip" {
  description = "The mount IP address of the replica NetApp volume (if cross-zone replication is enabled)"
  value       = var.netapp_enable_cross_zone_replication ? azurerm_netapp_volume.anf_replica[0].mount_ip_addresses : null
}
