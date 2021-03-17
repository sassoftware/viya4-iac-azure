# Sourced and modified from https://github.com/Azure/terraform-azurerm-vnet
locals {
  vnet_name = coalesce(var.name, "${var.prefix}-vnet")
}

data "azurerm_virtual_network" "vnet" {
  count               = var.name == "" ? 0 : 1
  name                = local.vnet_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  count               = var.name == "" ? 1 : 0
  name                = local.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

data "azurerm_subnet" "subnet" {
  count                = length(var.existing_subnets)
  name                 = var.existing_subnets[count.index]
  virtual_network_name = local.vnet_name
  resource_group_name  = var.resource_group_name
  depends_on           = [data.azurerm_virtual_network.vnet, azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "subnet" {
  count                                          = length(var.existing_subnets) == 0 ? length(var.subnets) : 0
  name                                           = "${var.prefix}-${var.subnets[count.index].name}"
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = local.vnet_name
  address_prefixes                               = var.subnets[count.index].prefixes
  service_endpoints                              = var.subnets[count.index].service_endpoints
  enforce_private_link_endpoint_network_policies = var.subnets[count.index].enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies  = var.subnets[count.index].enforce_private_link_service_network_policies
  depends_on                                     = [data.azurerm_virtual_network.vnet, azurerm_virtual_network.vnet]
}