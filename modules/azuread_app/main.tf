# Reference: https://github.com/terraform-providers/terraform-provider-azuread#using-the-provider
# provider "azuread" {
#   version = ">=0.7.0"
# }

# Create an AzureAD application and Service Principal for Terraform to manage Azure resources
# Reference: https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html
# watch out for potential issues
#  * https://github.com/Azure/AKS/issues/1206
#  * https://github.com/Azure/azure-cli/issues/9585

resource "azuread_application" "tfapp" {
  name = var.app_name
}

# Create a service principal
resource "azuread_service_principal" "tfapp_sp" {
  application_id = azuread_application.tfapp.application_id
  app_role_assignment_required = false
}

# Generate random password to be used for Service Principal password
resource "random_password" "password" {
  length  = 32
  special = true
}

# Create a Password for the Service Principal
resource "azuread_service_principal_password" "tfapp_sp_password" {
  service_principal_id = azuread_service_principal.tfapp_sp.id
  value                = random_password.password.result
  end_date_relative    = "17520h" #expire in 2 years
}
