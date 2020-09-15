output "app_id" {
  value = "${azuread_application.tfapp.application_id}"
}
output "app_name" {
  value = "${azuread_service_principal.tfapp_sp.display_name}"
}

output "app_sp_password" {
  value     = "${azuread_service_principal_password.tfapp_sp_password.value}"
  sensitive = true
}

output "app_sp_id" {
  value = "${azuread_service_principal.tfapp_sp.id}"
}