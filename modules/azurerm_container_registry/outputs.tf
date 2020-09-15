output "acr_login_server" {
  value = var.create_container_registry ? "${azurerm_container_registry.acr[0].login_server}" : null
}

output "acr_id" {
  value = var.create_container_registry ? "${azurerm_container_registry.acr[0].id}" : null
}