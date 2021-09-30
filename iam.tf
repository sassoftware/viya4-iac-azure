data "azurerm_user_assigned_identity" "uai" {
  count               = var.aks_uai_name == null ? 0 : 1
  name                = var.aks_uai_name
  resource_group_name = local.byo_resource_group_name
}

resource "azurerm_user_assigned_identity" "uai" {
  count               =  var.aks_uai_name == null ? 1 : 0
  name                = "${var.prefix}-aks-identity"
  resource_group_name = module.resource_group.name
  location            = var.location
}

resource "azurerm_role_assignment" "uai_role" {
  count                = var.aks_uai_name == null ? 1 : 0
  scope                = module.resource_group.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.uai.0.principal_id
}


### TODO remove before push
output "aks_uai_id" {
  value = local.aks_uai_id
}
