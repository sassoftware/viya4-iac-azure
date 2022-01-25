output "server_name" {
  description = "The name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.flexpsql.name
}

output "server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.flexpsql.fqdn
}

output "administrator_login" {
  value = var.administrator_login
}

output "administrator_password" {
  value     = var.administrator_password
  sensitive = true
}

output "server_id" {
  description = "The resource id of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.flexpsql.id
}

output "firewall_rule_ids" {
  description = "The list of all firewall rule resource ids"
  value       = [azurerm_postgresql_flexible_server_firewall_rule.flexpsql_firewall_rules.*.id]
}
