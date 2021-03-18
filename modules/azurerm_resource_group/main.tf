resource "azurerm_resource_group" "azure_rg" {
  count    = var.name ? 1 : 0
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "azure_rg" {
  count    = var.name ? 0 : 1
  name     = var.name
}