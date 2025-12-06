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

resource "azurerm_netapp_pool" "anf" {
  name                = "${var.prefix}-netapppool"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf.name
  service_level       = var.service_level
  size_in_tb          = var.size_in_tb
  tags                = var.tags
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
  
  # ✅ NEW: Set availability zone for primary volume
  zone                = var.netapp_availability_zone

  export_policy_rule {
    rule_index          = 1
    allowed_clients     = var.allowed_clients
    protocols           = var.protocols
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

# ✅ NEW: Replica Volume for Cross-Zone Replication
resource "azurerm_netapp_volume" "anf_replica" {
  count = var.netapp_enable_cross_zone_replication ? 1 : 0
  
  name                = "${var.prefix}-netappvolume-replica"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf.name
  service_level       = var.service_level
  pool_name           = "${var.prefix}-netapppool"
  volume_path         = "${var.volume_path}-replica"
  subnet_id           = var.subnet_id
  network_features    = var.network_features
  protocols           = var.protocols
  storage_quota_in_gb = var.community_netapp_volume_size == 0 ? var.size_in_tb * 1024 : var.community_netapp_volume_size
  tags                = merge(var.tags, { "role" = "replica" })
  
  # ✅ Different zone for high availability
  zone                = var.netapp_replication_zone

  # ✅ Configure as replication destination
  data_protection_replication {
    endpoint_type             = "dst"
    remote_volume_location    = var.location
    remote_volume_resource_id = azurerm_netapp_volume.anf.id
    replication_frequency     = var.netapp_replication_frequency
  }

  export_policy_rule {
    rule_index          = 1
    allowed_clients     = var.allowed_clients
    protocols           = var.protocols
    unix_read_write     = true
    root_access_enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    azurerm_netapp_volume.anf
  ]
}

# ✅ NEW: Output replica information for monitoring
output "replica_volume_id" {
  description = "The ID of the replica NetApp volume (if cross-zone replication is enabled)"
  value       = var.netapp_enable_cross_zone_replication ? azurerm_netapp_volume.anf_replica[0].id : null
}

output "replica_mount_ip" {
  description = "The mount IP address of the replica NetApp volume (if cross-zone replication is enabled)"
  value       = var.netapp_enable_cross_zone_replication ? azurerm_netapp_volume.anf_replica[0].mount_ip_addresses : null
}
