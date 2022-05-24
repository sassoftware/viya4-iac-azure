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


# resource "azurerm_role_assignment" "ra1" {
#   scope                = data.azurerm_subnet.kubesubnet.id
#   role_definition_name = "Network Contributor"
#   principal_id         = var.aks_service_principal_object_id

#   depends_on = [azurerm_virtual_network.test]
# }

resource "azurerm_role_assignment" "ra2" {
  scope                = local.aks_rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.uai.0.principal_id
  depends_on           = [azurerm_user_assigned_identity.uai]
}

resource "azurerm_role_assignment" "ra3" {
  scope                = local.aks_rg.id
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.uai.0.principal_id
  depends_on           = [azurerm_user_assigned_identity.uai]
}

resource "azurerm_role_assignment" "ra4" {
  scope                = "/subscriptions/76f40aaa-eacd-4fd8-a046-3bd07855f6f8/resourceGroups/shd-network-rg-n" #/providers/Microsoft.Network/routeTables/shd-inf-sas-k8s-10.23.8.64-26-rtt-n"
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.uai.0.principal_id
  depends_on           = [azurerm_user_assigned_identity.uai]
}

# resource "azurerm_role_assignment" "ra4" {
#   scope                = azurerm_resource_group.rg.id
#   role_definition_name = "Reader"
#   principal_id         = azurerm_user_assigned_identity.uai.principal_id
#   # depends_on           = [azurerm_user_assigned_identity.uai, azurerm_application_gateway.network]
# }