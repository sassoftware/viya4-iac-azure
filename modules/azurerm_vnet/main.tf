# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
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

  # NOTE: IPv6 is managed at the subnet level via ipv6_address_prefix.
  # The Terraform azurerm provider does not support ipv6_address_space
  # as a VNet-level argument. IPv6 subnets are created with /64 prefixes
  # allocated from the ipv6_address_space when enable_ipv6=true.
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
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
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

  # NOTE: IPv6 subnet prefix allocation is not yet supported by the Terraform
  # azurerm provider. To enable IPv6 on subnets, you can:
  #  - Use the `azapi` provider for IPv6 subnet configuration
  #  - Or configure IPv6 subnets manually via Azure Portal/CLI after initial VNet creation
  # IPv6 prefixes must be /64 CIDR blocks allocated from the VNet's /48 space.
  # Example prefixes (to be applied manually or via azapi):
  #  - aks subnet:     2001:db8:0000::/64
  #  - misc subnet:    2001:db8:0001::/64
  #  - netapp subnet:  2001:db8:0002::/64

  depends_on = [data.azurerm_virtual_network.vnet, azurerm_virtual_network.vnet]
}

resource "azurerm_role_assignment" "existing_network_assignment" {
    count = length(var.existing_subnets) == 0 ? 0 : (var.add_uai_permissions ? length(var.roles) : 0)
    scope = data.azurerm_subnet.subnet["aks"].route_table_id
    role_definition_name = var.roles[count.index]
    principal_id = var.aks_uai_principal_id
}

resource "azurerm_role_assignment" "existing_vnet_assignment" {
  count = var.name != null ? (var.add_uai_permissions ? length(var.roles) : 0) : 0
  scope = data.azurerm_virtual_network.vnet[0].id
  role_definition_name = var.roles[count.index]
  principal_id = var.aks_uai_principal_id
}
