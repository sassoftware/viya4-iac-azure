# Terraform docs - https://www.terraform.io/docs/providers/azurerm/r/netapp_volume.html
# Terraform Registry - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/netapp_volume
# Azure docs - https://docs.microsoft.com/en-us/azure/azure-netapp-files/


# TODO: changer after upgrading to v0.13 
# https://github.com/terraform-providers/terraform-provider-azurerm/issues/5233
# data "azurerm_resource_group" "anf" {
#   name = var.resource_group_name
# }

resource "azurerm_subnet" "anf" {
  count                = var.create_netapp ? 1 : 0
  name                 = "${var.prefix}-netapp"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.subnet_address_prefix

  delegation {
    name = "netapp"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_netapp_account" "anf" {
  count               = var.create_netapp ? 1 : 0
  name                = "${var.prefix}-netappaccount"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_netapp_pool" "anf" {
  count               = var.create_netapp ? 1 : 0
  name                = "${var.prefix}-netapppool"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf[0].name
  service_level       = var.service_level
  size_in_tb          = var.size_in_tb
}

resource "azurerm_netapp_volume" "anf" {
  count               = var.create_netapp ? 1 : 0
  name                = "${var.prefix}-netappvolume"
  location            = var.location
  resource_group_name = var.resource_group_name
  account_name        = azurerm_netapp_account.anf[0].name
  service_level       = var.service_level
  pool_name           = "${var.prefix}-netapppool"
  volume_path         = var.volume_path
  subnet_id           = azurerm_subnet.anf[0].id
  protocols           = var.protocols
  storage_quota_in_gb = var.size_in_tb * 1024

  export_policy_rule {
    rule_index = 1
    allowed_clients = var.allowed_clients
    protocols_enabled = var.protocols
    unix_read_write = true
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    azurerm_netapp_pool.anf
  ]
}