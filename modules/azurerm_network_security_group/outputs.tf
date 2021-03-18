output "id" {
  description = "The id of the NSG"
  value       = element(coalescelist(data.azurerm_network_security_group.nsg.*.id, azurerm_network_security_group.nsg.*.id), 0)
}

output "name" {
  description = "The name of the NSG"
  value       = coalesce(var.name, "${var.prefix}-nsg")
}