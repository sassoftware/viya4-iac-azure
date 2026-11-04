# Copyright © 2026, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# ANF does not support dual-stack VNets. Keep storage IPv4-only and peer it
# with the AKS VNet so dual-stack clients can mount NFS over IPv4.
data "azurerm_virtual_network" "netapp_clients" {
  count = local.create_netapp_ipv4_vnet ? 1 : 0

  name                = "${var.prefix}-vnet"
  resource_group_name = local.network_rg.name
  depends_on          = [azurerm_resource_group_template_deployment.vnet_ipv6]
}

resource "azurerm_virtual_network" "netapp_ipv4" {
  count = local.create_netapp_ipv4_vnet ? 1 : 0

  name                = "${var.prefix}-netapp-vnet"
  location            = var.location
  resource_group_name = local.network_rg.name
  address_space       = [var.netapp_vnet_address_space]
  tags                = var.tags

  lifecycle {
    precondition {
      condition = (
        cidrhost("${cidrhost(var.netapp_vnet_address_space, 0)}/${split("/", var.vnet_address_space)[1]}", 0) != cidrhost(var.vnet_address_space, 0) &&
        cidrhost("${cidrhost(var.vnet_address_space, 0)}/${split("/", var.netapp_vnet_address_space)[1]}", 0) != cidrhost(var.netapp_vnet_address_space, 0)
      )
      error_message = "netapp_vnet_address_space must not overlap vnet_address_space; Azure VNet peering requires non-overlapping address spaces."
    }
  }
}

resource "azurerm_subnet" "netapp_ipv4" {
  count = local.create_netapp_ipv4_vnet ? 1 : 0

  name                                          = "${var.prefix}-netapp-subnet"
  resource_group_name                           = local.network_rg.name
  virtual_network_name                          = azurerm_virtual_network.netapp_ipv4[0].name
  address_prefixes                              = [var.netapp_vnet_address_space]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false

  delegation {
    name = "netapp"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_virtual_network_peering" "aks_to_netapp" {
  count = local.create_netapp_ipv4_vnet ? 1 : 0

  name                         = "${var.prefix}-aks-to-netapp"
  resource_group_name          = local.network_rg.name
  virtual_network_name         = data.azurerm_virtual_network.netapp_clients[0].name
  remote_virtual_network_id    = azurerm_virtual_network.netapp_ipv4[0].id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "netapp_to_aks" {
  count = local.create_netapp_ipv4_vnet ? 1 : 0

  name                         = "${var.prefix}-netapp-to-aks"
  resource_group_name          = local.network_rg.name
  virtual_network_name         = azurerm_virtual_network.netapp_ipv4[0].name
  remote_virtual_network_id    = data.azurerm_virtual_network.netapp_clients[0].id
  allow_virtual_network_access = true

  depends_on = [azurerm_virtual_network_peering.aks_to_netapp]
}
