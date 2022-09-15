###################################################
### Managed PostgreSQL Flexible server on Azure ###
###################################################
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server
#

resource "azurerm_postgresql_flexible_server" "flexpsql" {

  name                         = "${var.server_name}-flexpsql"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  sku_name                     = var.sku_name
  storage_mb                   = var.storage_mb
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
  administrator_login          = var.administrator_login
  administrator_password       = var.administrator_password
  version                      = var.server_version
  tags                         = var.tags

  lifecycle {
    ignore_changes = [ 
      # Ignore changes to zone on updates after intial creation
      zone
    ]  
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "flexpsql" {
  for_each   = {
    for config in var.postgresql_configurations:
      config.name => config
  }

  name       = each.value.name
  server_id  = azurerm_postgresql_flexible_server.flexpsql.id
  value      = each.value.value
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "flexpsql" {
  count = length(var.firewall_rules)

  name             = format("%s%s", var.firewall_rule_prefix, lookup(var.firewall_rules[count.index], "name", count.index))
  server_id        = azurerm_postgresql_flexible_server.flexpsql.id
  start_ip_address = var.firewall_rules[count.index]["start_ip"]
  end_ip_address   = var.firewall_rules[count.index]["end_ip"]
}

# NOTE: This firewall rule enables the flag - "Allow public access from any Azure service within Azure to this server"
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_public" {

  name             = "Allow-public-access-from-any-Azure-service"
  server_id        = azurerm_postgresql_flexible_server.flexpsql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
