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
  value       = element(coalescelist(data.azurerm_virtual_network.vnet.*.address_space, azurerm_virtual_network.vnet.*.address_space), 0)
}

output "subnets" {
  description = "The ids of subnets inside the vNet"
  value = var.existing_subnets == null ? [for k, v in azurerm_subnet.subnet[*] :{for kk, vv in v: kk => {"id": vv.id, "address_prefixes": vv.address_prefixes }}][0] : [for k, v in data.azurerm_subnet.subnet[*] :{for kk, vv in v: kk => {"id": vv.id, "address_prefixes": vv.address_prefixes }}][0]
}