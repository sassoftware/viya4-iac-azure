resource "azurerm_subnet" "subnet" {
  name                 = "${var.name}-subnet"
  resource_group_name  = var.azure_rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.address_prefixes
  service_endpoints    = var.service_endpoints
}

# https://www.terraform.io/docs/providers/azurerm/r/subnet_network_security_group_association.html
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  count                     = var.nsg == null ? 0 : 1
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = var.nsg.id
}