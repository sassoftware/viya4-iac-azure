# Azure Monitor - https://azure.microsoft.com/en-gb/services/monitor/
# Azure Docs 
# - https://docs.microsoft.com/en-gb/azure/azure-monitor/log-query/log-analytics-overview
# - https://docs.microsoft.com/en-us/azure/azure-monitor/log-query/log-analytics-tutorial

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "viya4" {
  count               = var.create_aks_azure_monitor ? 1 : 0

  name                = "${var.prefix}-log-analytics-workspace"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_solution
resource "azurerm_log_analytics_solution" "viya4" {
  count               = var.create_aks_azure_monitor ? 1 : 0

  solution_name         = var.log_analytics_solution_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.azure_rg.name
  # workspace_resource_id = element(coalescelist(azurerm_log_analytics_workspace.viya4.*.id, [""]), 0)
  # workspace_name        = element(coalescelist(azurerm_log_analytics_workspace.viya4.*.name, [""]), 0)
  workspace_resource_id = azurerm_log_analytics_workspace.viya4[0].id
  workspace_name        = azurerm_log_analytics_workspace.viya4[0].name
  
  plan {
    publisher = var.log_analytics_solution_publisher
    product   = var.log_analytics_solution_product
    promotion_code = var.log_analytics_solution_promotion_code
  }

  tags = var.tags

}
