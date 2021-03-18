resource "azurerm_network_security_group" "nsg" {
  count               = var.name == "" ? 1 : 0
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

data "azurerm_network_security_group" "nsg" {
  count               = var.name == "" ? 0 : 1
  name                = var.name
  resource_group_name = var.resource_group_name
}