# Sourced and modified from https://github.com/Azure/terraform-azurerm-vnet
locals {
  vnet_name = coalesce(var.name, "${var.prefix}-vnet")
  subnets = ( length(var.existing_subnets) == 0 
              ? [ for k, v in azurerm_subnet.subnet[*] :{ for kk, vv in v: kk => {"id": vv.id, "address_prefixes": vv.address_prefixes }}][0] 
              : [ for k, v in data.azurerm_subnet.subnet[*] :{for kk, vv in v: kk => {"id": vv.id, "address_prefixes": vv.address_prefixes }}][0]
  )
  #nat_ip    = var.nat_gateway_name == "" ? azurerm_public_ip.nat-gw-ip.0.ip_address : 0
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
  for_each                                       = length(var.existing_subnets) == 0 ? var.subnets : {}
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

#
# NAT Gateway - aks needs it, else the VMs have issues calling out (helpful video at https://docs.microsoft.com/en-us/azure/virtual-network/nat-gateway/nat-overview)
#
# resource "azurerm_public_ip" "nat-gw-ip" {
#   count               = var.nat_gateway_name == "" ? 1 : 0
#   name                = "${var.prefix}-nat-gateway-publicIP"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   tags                = var.tags
# }

# # resource "azurerm_public_ip_prefix" "nat-gw-ip-prefix" {
# #   count               = var.nat_gateway_name == null ? 1 : 0
# #   name                = "${var.prefix}-nat-gateway-publicIPPrefix"
# #   location            = var.location
# #   resource_group_name = var.resource_group_name
# #   prefix_length       = 30
# #   tags                = var.tags
# # }

# resource "azurerm_nat_gateway" "nat-gw" {
#   count               = var.nat_gateway_name == "" ? 1 : 0
#   name                = "${var.prefix}-nat-gw"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   tags                = var.tags
# }

# resource "azurerm_subnet_nat_gateway_association" "nat-gw-subnet-assoc" {
#   count          = var.nat_gateway_name == "" ? 1 : 0
#   subnet_id      = local.subnets["aks"].id
#   nat_gateway_id = azurerm_nat_gateway.nat-gw.0.id
# }
# resource "azurerm_nat_gateway_public_ip_association" "nat-gw-ip-assoc" {
#   count                = var.nat_gateway_name == "" ? 1 : 0
#   public_ip_address_id = azurerm_public_ip.nat-gw-ip.0.id
#   nat_gateway_id       = azurerm_nat_gateway.nat-gw.0.id
# }
# # resource "azurerm_nat_gateway_public_ip_prefix_association" "nat-gw-ip-prefix-assoc" {
# #   count               = var.nat_gateway_name == null ? 1 : 0
# #   public_ip_prefix_id = azurerm_public_ip_prefix.nat-gw-ip-prefix.0.id
# #   nat_gateway_id      = azurerm_nat_gateway.nat-gw.0.id
# # }

# data "azurerm_nat_gateway" "nat-gw" {
#   count               = var.nat_gateway_name == "" ? 0 : 1
#   name                = var.nat_gateway_name
#   resource_group_name = var.resource_group_name
# }


