# Reference: https://github.com/terraform-providers/terraform-provider-azurerm
resource "azurerm_resource_group" "azure_rg" {
    name = var.azure_rg_name
    location = var.azure_rg_location
    tags = var.tags
}