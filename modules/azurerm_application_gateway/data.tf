# Lookup Key Vault by name (only if creating identity and Key Vault name provided)
data "azurerm_key_vault" "main" {
  count               = var.create_app_gateway && local.should_create_identity && var.key_vault_name != null ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name != null ? var.key_vault_resource_group_name : var.resource_group_name
}
