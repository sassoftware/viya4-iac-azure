# Sourced and modified from https://github.com/Azure/terraform-azurerm-vnet
locals {
  vnet_name = coalesce(var.name, "${var.prefix}-vnet")
  subnets = var.existing_subnets == null ? var.subnets : {} 
}

data "azurerm_virtual_network" "vnet" {
  count               = var.name ? 0 : 1
  name                = local.vnet_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  count               = var.name ? 1 : 0
  name                = local.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

data "azurerm_subnet" "subnet" {
  for_each             = var.existing_subnets == null ? {} : var.existing_subnets
  name                 = each.value
  virtual_network_name = local.vnet_name
  resource_group_name  = var.resource_group_name
  depends_on           = [data.azurerm_virtual_network.vnet, azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "subnet" {
  for_each                                       = local.subnets
  name                                           = "${var.prefix}-${each.key}-subnet"
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = local.vnet_name
  address_prefixes                               = each.value.prefixes
  service_endpoints                              = each.value.service_endpoints
  enforce_private_link_endpoint_network_policies = each.value.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = each.value.enforce_private_link_service_network_policies
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

  depends_on                                     = [data.azurerm_virtual_network.vnet, azurerm_virtual_network.vnet]  
}