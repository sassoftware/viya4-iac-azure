output "postgres_server_name" {
  description = "The name of the PostgreSQL server"
  value       = var.create_postgres ? azurerm_postgresql_server.server[0].name : null
}

output "postgres_server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the PostgreSQL server"
  value       = var.create_postgres ? azurerm_postgresql_server.server[0].fqdn : null
}

output "postgres_administrator_login" {
  value = var.create_postgres ? azurerm_postgresql_server.server[0].administrator_login : null
}

output "postgres_administrator_password" {
  value     = var.create_postgres ? azurerm_postgresql_server.server[0].administrator_login_password : null
  sensitive = true
}

output "postgres_server_id" {
  description = "The resource id of the PostgreSQL server"
  value       = var.create_postgres ? azurerm_postgresql_server.server[0].id : null
}

output "postgres_database_ids" {
  description = "The list of all database resource ids"
  value       = var.create_postgres ? [azurerm_postgresql_database.dbs.*.id] : null
}

output "postgres_firewall_rule_ids" {
  description = "The list of all firewall rule resource ids"
  value       = var.create_postgres ? [azurerm_postgresql_firewall_rule.postgres_firewall_rules.*.id] : null
}

output "postgres_vnet_rule_ids" {
  description = "The list of all vnet rule resource ids"
  value       = var.create_postgres ? [azurerm_postgresql_virtual_network_rule.postgres_vnet_rules.*.id] : null
}