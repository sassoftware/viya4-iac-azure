output "id" {
  description = "The id of the vNet"
  value       = var.name == null ? azurerm_virtual_network.vnet.0.id : data.azurerm_virtual_network.vnet.0.id
}

output "name" {
  description = "The Name of the vNet"
  value       = local.vnet_name
}

output "location" {
  description = "The location of the vNet"
  value       = var.name == null ? azurerm_virtual_network.vnet.0.location : data.azurerm_virtual_network.vnet.0.location
}

output "address_space" {
  description = "The address space of the vNet"
  value       = var.name == null ? azurerm_virtual_network.vnet.0.address_space : data.azurerm_virtual_network.vnet.0.address_space
}

output "subnets" {
  description = "The ids of subnets inside the vNet"
  value       = local.subnets
}

# output "nat_ip" {
#   description = "The primary public IP of the NAT Gateway"
#   value       = local.nat_ip
# }
