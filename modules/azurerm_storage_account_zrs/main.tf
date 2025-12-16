# Copyright © 2020-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Azure Storage Account with Zone-Redundant Storage (ZRS)
# Provides automatic cross-zone failover for SAS Viya multi-AZ deployments

resource "azurerm_storage_account" "zrs" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = "ZRS"  # Zone-redundant storage for automatic failover
  account_kind             = "FileStorage"

  # Security settings
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Network security
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = var.allowed_subnet_ids
    bypass                     = ["AzureServices"]
    ip_rules                   = var.allowed_ip_ranges
  }

  tags = var.tags
}

# NFS share for SAS Viya workloads
resource "azurerm_storage_share" "viya" {
  name                 = var.share_name
  storage_account_name = azurerm_storage_account.zrs.name
  quota                = var.quota_gb

  # NFS 4.1 protocol (required for Kubernetes NFS provisioner)
  enabled_protocol = "NFS"

  # Access tier for Premium storage
  access_tier = var.account_tier == "Premium" ? null : "Hot"

  depends_on = [azurerm_storage_account.zrs]
}

# Private endpoint for secure VNet access
resource "azurerm_private_endpoint" "storage" {
  count               = var.create_private_endpoint ? 1 : 0
  name                = "${var.storage_account_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-psc"
    private_connection_resource_id = azurerm_storage_account.zrs.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

# Private DNS A record for storage account (if using private endpoint)
resource "azurerm_private_dns_a_record" "storage" {
  count               = var.create_private_endpoint && var.create_dns_record ? 1 : 0
  name                = var.storage_account_name
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage[0].private_service_connection[0].private_ip_address]

  tags = var.tags
}
