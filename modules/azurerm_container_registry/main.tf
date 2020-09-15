# Reference: 
# Terraform - https://www.terraform.io/docs/providers/azurerm/r/container_registry.html
# Azure - https://azure.microsoft.com/en-gb/services/container-registry
# Tutorial - https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr

resource "azurerm_container_registry" "acr" {
  count                    = var.create_container_registry ? 1 : 0

  name                     = var.container_registry_name
  resource_group_name      = var.container_registry_rg
  location                 = var.container_registry_location
  sku                      = var.container_registry_sku
  admin_enabled            = var.container_registry_admin_enabled
  georeplication_locations = var.container_registry_geo_replica_locs 
}