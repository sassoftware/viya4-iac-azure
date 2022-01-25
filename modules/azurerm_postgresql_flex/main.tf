# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server
resource "azurerm_postgresql_flexible_server" "flexpsql" {

  name                   = var.server_name
  location               = var.location
  resource_group_name    = var.resource_group_name
  
  sku_name               = var.sku_name
  
  storage_mb             = var.storage_mb
  backup_retention_days  = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  version                = var.server_version
  tags                   = var.tags
  
  ## TODO: add required 'private_dns_zone_id' since July 2021
  # delegated_subnet_id    = var.delegated_subnet_id
}

resource "azurerm_postgresql_flexible_server_configuration" "flexpsql_config" {
  count     = length(keys(var.postgresql_configurations))
  
  name      = element(keys(var.postgresql_configurations), count.index)
  server_id = azurerm_postgresql_flexible_server.flexpsql.id
  value     = element(values(var.postgresql_configurations), count.index)
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "flexpsql_firewall_rules" {
  count            = length(var.firewall_rules)
  
  name             = format("%s%s", var.firewall_rule_prefix, lookup(var.firewall_rules[count.index], "name", count.index))
  server_id        = azurerm_postgresql_flexible_server.flexpsql.id
  start_ip_address    = var.firewall_rules[count.index]["start_ip"]
  end_ip_address      = var.firewall_rules[count.index]["end_ip"]
}
