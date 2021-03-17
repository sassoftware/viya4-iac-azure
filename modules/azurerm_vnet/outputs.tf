output "id" {
  description = "The id of the vNet"
  value       = element(coalesce(data.azurerm_virtual_network.vnet.*.id, azurerm_virtual_network.vnet.*.id), 0)
}

output "name" {
  description = "The Name of the vNet"
  value       = local.vnet_name
}

output "location" {
  description = "The location of the vNet"
  value       = element(coalesce(data.azurerm_virtual_network.vnet.*.location, azurerm_virtual_network.vnet.*.location), 0)
}

output "address_space" {
  description = "The address space of the vNet"
  value       = element(coalesce([data.azurerm_virtual_network.vnet.*.address_space], azurerm_virtual_network.vnet.*.address_space), 0)
}

output "subnets" {
  description = "The ids of subnets inside the vNet"
  value       = length(var.existing_subnets) == 0 ? azurerm_virtual_network.vnet.*.id : data.azurerm_virtual_network.vnet.*.id
}