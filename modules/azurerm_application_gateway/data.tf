# Lookup Key Vault by name (when certificate_name is used)
data "azurerm_key_vault" "main" {
  count               = var.create_app_gateway && var.key_vault_name != null ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name != null ? var.key_vault_resource_group_name : var.resource_group_name
}

# Lookup SSL certificate from Key Vault by certificate name
data "azurerm_key_vault_certificate" "ssl_cert" {
  count        = var.create_app_gateway && var.app_gateway_config != null && lookup(var.app_gateway_config, "ssl_certificate", null) != null ? length([for cert in var.app_gateway_config.ssl_certificate : cert if lookup(cert, "certificate_name", null) != null && lookup(cert, "data", null) == null]) : 0
  name         = var.app_gateway_config.ssl_certificate[count.index].certificate_name
  key_vault_id = data.azurerm_key_vault.main[0].id
}

# Lookup backend trusted root certificate from Key Vault by certificate name
data "azurerm_key_vault_certificate" "backend_cert" {
  count        = var.create_app_gateway && var.app_gateway_config != null && lookup(var.app_gateway_config, "backend_trusted_root_certificate", null) != null ? length([for cert in var.app_gateway_config.backend_trusted_root_certificate : cert if lookup(cert, "certificate_name", null) != null && lookup(cert, "data", null) == null]) : 0
  name         = var.app_gateway_config.backend_trusted_root_certificate[count.index].certificate_name
  key_vault_id = data.azurerm_key_vault.main[0].id
}
