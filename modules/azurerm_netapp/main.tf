# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Terraform docs - https://www.terraform.io/docs/providers/azurerm/r/netapp_volume.html
# Terraform Registry - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/netapp_volume
# Azure docs - https://docs.microsoft.com/en-us/azure/azure-netapp-files/

resource "azurerm_netapp_account" "anf" {
  name                = "${var.prefix}-netappaccount"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "identity" {
    for_each = var.netapp_enable_cmk_encryption ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.netapp_cmk_encryption_key_uai]
    }
  }
}

resource "azurerm_netapp_account_encryption" "anf" {
  count = var.netapp_enable_cmk_encryption ? 1 : 0

  netapp_account_id         = azurerm_netapp_account.anf.id
  encryption_key            = var.netapp_cmk_encryption_key_id
  user_assigned_identity_id = var.netapp_cmk_encryption_key_uai
}

resource "azurerm_netapp_pool" "anf" {
  name                = "${var.prefix}-netapppool"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf.name
  service_level       = var.service_level
  size_in_tb          = var.size_in_tb
  tags                = var.tags
  
  depends_on = [
    azurerm_netapp_account_encryption.anf
  ]
}

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
  tags                = var.tags

  export_policy_rule {
    rule_index          = 1
    allowed_clients     = var.allowed_clients
    protocols_enabled   = var.protocols
    unix_read_write     = true
    root_access_enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    azurerm_netapp_pool.anf,
    azurerm_netapp_account_encryption.anf
  ]
}

