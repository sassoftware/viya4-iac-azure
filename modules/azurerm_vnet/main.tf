# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Sourced and modified from https://github.com/Azure/terraform-azurerm-vnet
locals {
  vnet_name = coalesce(var.name, "${var.prefix}-vnet")
  subnets = (length(var.existing_subnets) == 0
    ? [for k, v in azurerm_subnet.subnet[*] : { for kk, vv in v : kk => { "id" : vv.id, "address_prefixes" : vv.address_prefixes } }][0]
    : [for k, v in data.azurerm_subnet.subnet[*] : { for kk, vv in v : kk => { "id" : vv.id, "address_prefixes" : vv.address_prefixes } }][0]
  )
}

data "azurerm_virtual_network" "vnet" {
  count               = var.name == null ? 0 : 1
  name                = local.vnet_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  count               = var.name == null ? 1 : 0
  name                = local.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

data "azurerm_subnet" "subnet" {
  for_each             = length(var.existing_subnets) == 0 ? {} : var.existing_subnets
  name                 = each.value
  virtual_network_name = local.vnet_name
  resource_group_name  = var.resource_group_name
  depends_on           = [data.azurerm_virtual_network.vnet, azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "subnet" {
  for_each                                      = length(var.existing_subnets) == 0 ? var.subnets : {}
  name                                          = "${var.prefix}-${each.key}-subnet"
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = local.vnet_name
  address_prefixes                              = each.value.prefixes
  service_endpoints                             = each.value.service_endpoints
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  dynamic "delegation" {
    for_each = each.value.service_delegations
    content {
      name = delegation.key

      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }

  depends_on = [data.azurerm_virtual_network.vnet, azurerm_virtual_network.vnet]
}

