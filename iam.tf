data "azurerm_user_assigned_identity" "uai" {
  count               = var.aks_identity == "uai" ? ( var.aks_uai_name == null ? 0 : 1 ) : 0
  name                = var.aks_uai_name
  resource_group_name = local.network_rg.name
}

resource "azurerm_user_assigned_identity" "uai" {
  count               = var.aks_identity == "uai" ? ( var.aks_uai_name == null ? 1 : 0 ) : 0
  name                = "${var.prefix}-aks-identity"
  resource_group_name = local.aks_rg.name
  location            = var.location
}

# need to be able to read and write custom route table in the BYO network
resource "azurerm_role_assignment" "uai_byo_rg_role" {
  count                = ( var.aks_identity == "uai"
                           ? ( var.aks_uai_name == null
                               ? ( var.vnet_name == null ? 0 : 1 )
                               : 0
                             )
                           : 0
                         )
  scope                = local.network_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.uai.0.principal_id
}