output "id" {
  description = "Application Gateway ID"
  value       = var.create_app_gateway ? azurerm_application_gateway.appgw[0].id : null
}

output "name" {
  description = "Application Gateway name"
  value       = var.create_app_gateway ? azurerm_application_gateway.appgw[0].name : null
}

output "public_ip_id" {
  description = "Public IP ID (if created)"
  value       = var.create_app_gateway && var.create_public_ip ? azurerm_public_ip.appgw[0].id : null
}

output "public_ip_address" {
  description = "Public IP address (if created)"
  value       = var.create_app_gateway && var.create_public_ip ? azurerm_public_ip.appgw[0].ip_address : null
}

output "backend_address_pool_ids" {
  description = "Backend address pool IDs"
  value       = var.create_app_gateway ? azurerm_application_gateway.appgw[0].backend_address_pool[*].id : []
}

output "waf_policy_id" {
  description = "WAF Policy ID (created or provided)"
  value       = local.waf_policy
}

output "waf_enabled" {
  description = "Whether WAF is enabled"
  value       = var.enable_waf
}

output "identity_id" {
  description = "User-Assigned Identity ID (if created)"
  value       = var.create_app_gateway ? try(azurerm_user_assigned_identity.appgw[0].id, null) : null
}

output "identity_principal_id" {
  description = "User-Assigned Identity Principal ID (if created)"
  value       = var.create_app_gateway ? try(azurerm_user_assigned_identity.appgw[0].principal_id, null) : null
}

output "identity_client_id" {
  description = "User-Assigned Identity Client ID (if created)"
  value       = var.create_app_gateway ? try(azurerm_user_assigned_identity.appgw[0].client_id, null) : null
}
