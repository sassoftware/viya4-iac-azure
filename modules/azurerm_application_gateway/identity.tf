# Create User-Assigned Identity (auto-created when Key Vault certs are used)
resource "azurerm_user_assigned_identity" "appgw" {
  count               = var.create_app_gateway && local.should_create_identity ? 1 : 0
  name                = "${local.base_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
