output "postgres_server_name" {
  description = "The name of the PostgreSQL server"
  value       = azurerm_postgresql_server.server.name
}

output "postgres_server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the PostgreSQL server"
  value       = azurerm_postgresql_server.server.fqdn
}

output "postgres_administrator_login" {
  value = azurerm_postgresql_server.server.administrator_login
}

output "postgres_administrator_password" {
  value     = azurerm_postgresql_server.server.administrator_login_password
  sensitive = true
}

output "postgres_server_id" {
  description = "The resource id of the PostgreSQL server"
  value       = azurerm_postgresql_server.server.id
}

output "postgres_database_ids" {
  description = "The list of all database resource ids"
  value       = [azurerm_postgresql_database.dbs.*.id]
}

output "postgres_firewall_rule_ids" {
  description = "The list of all firewall rule resource ids"
  value       = [azurerm_postgresql_firewall_rule.postgres_firewall_rules.*.id]
}

output "postgres_vnet_rule_ids" {
  description = "The list of all vnet rule resource ids"
  value       = [azurerm_postgresql_virtual_network_rule.postgres_vnet_rules.*.id]
}
