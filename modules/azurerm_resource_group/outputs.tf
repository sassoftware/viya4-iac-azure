output "id" {
  description = "The id of the newly created resource group"
  value       = element(coalescelist(data.azurerm_resource_group.azure_rg.*.id, azurerm_resource_group.azure_rg.*.id), 0)
}

output "name" {
  description = "The Name of the newly created resource group"
  value       = coalesce(var.name, "${var.prefix}-rg")
}

output "location" {
  description = "The location of the newly created resource group"
  value       = element(coalescelist([var.location], data.azurerm_resource_group.azure_rg.*.location), 0)
}

output "tags" {
  description = "The tags of the newly created resource group"
  value       = element(coalescelist([var.tags], data.azurerm_resource_group.azure_rg.*.tags), 0)
}