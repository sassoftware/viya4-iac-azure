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
}

resource "azurerm_netapp_pool" "anf" {
  name                = "${var.prefix}-netapppool"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf.name
  service_level       = var.service_level
  size_in_tb          = var.size_in_tb
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.size_in_tb != 1 || var.network_features == "Standard"
      error_message = "You can only take advantage of the 1-TiB minimum if all the volumes in the capacity pool are using Standard network features. If any volume is using Basic network features, the minimum size is 4 TiB."
    }
  }

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
  storage_quota_in_gb = var.size_in_tb * 1024
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
    azurerm_netapp_pool.anf
  ]
}
