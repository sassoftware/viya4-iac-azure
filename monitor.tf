# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Azure Monitor - https://azure.microsoft.com/en-gb/services/monitor/
# Azure Docs 
# - https://docs.microsoft.com/en-gb/azure/azure-monitor/log-query/log-analytics-overview
# - https://docs.microsoft.com/en-us/azure/azure-monitor/log-query/log-analytics-tutorial

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "viya4" {
  count = var.create_aks_azure_monitor ? 1 : 0

  name                = "${var.prefix}-log-analytics-workspace"
  location            = var.location
  resource_group_name = local.aks_rg.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_solution
resource "azurerm_log_analytics_solution" "viya4" {
  count = var.create_aks_azure_monitor ? 1 : 0

  solution_name       = var.log_analytics_solution_name
  location            = var.location
  resource_group_name = local.aks_rg.name
  # workspace_resource_id = element(coalescelist(azurerm_log_analytics_workspace.viya4[*].id, [""]), 0)
  # workspace_name        = element(coalescelist(azurerm_log_analytics_workspace.viya4[*].name, [""]), 0)
  workspace_resource_id = azurerm_log_analytics_workspace.viya4[0].id
  workspace_name        = azurerm_log_analytics_workspace.viya4[0].name

  plan {
    publisher      = var.log_analytics_solution_publisher
    product        = var.log_analytics_solution_product
    promotion_code = var.log_analytics_solution_promotion_code
  }

  tags = var.tags

}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting

resource "azurerm_monitor_diagnostic_setting" "audit" {
  count = var.create_aks_azure_monitor ? 1 : 0

  name                       = "${var.prefix}-monitor_diagnostic_setting"
  target_resource_id         = module.aks.cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.viya4[0].id

  dynamic "enabled_log" {
    iterator = log_category
    for_each = var.resource_log_category

    content {
      category = log_category.value
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = var.metric_category

    content {
      category = metric_category.value
      enabled  = true
    }
  }
}
