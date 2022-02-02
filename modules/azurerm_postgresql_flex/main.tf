# Reference: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server

/***
NOTE: Based on Azure documentatin - https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-manage-virtual-network-portal
two networking features are supported - 
  1. Public access (allowed IP addresses)
  2. Private access (VNet Integration)

To support #2. VNet Integration, the inputs for Postgres will deviate too far from what is 
currently supported for single Postgresql server. 
*/

# resource "azurerm_private_dns_zone" "flexpsql" {
#   name                = "${var.server_name}.postgres.database.azure.com"
#   resource_group_name = var.resource_group_name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "flexpsql" {
#   name                  = var.server_name
#   private_dns_zone_name = azurerm_private_dns_zone.flexpsql.name
#   virtual_network_id    = var.virtual_network_id
#   resource_group_name   = var.resource_group_name
# }

resource "azurerm_postgresql_flexible_server" "flexpsql" {

  name                         = "${var.server_name}-flexpgsql"
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
  # delegated_subnet_id          = var.delegated_subnet_id
  # private_dns_zone_id          = azurerm_private_dns_zone.flexpsql.id

  # depends_on = [azurerm_private_dns_zone_virtual_network_link.flexpsql]

  lifecycle {
    ignore_changes = [ 
      # Ignore changes to zone on updates after intial creation
      zone
    ]  
  }
}


resource "azurerm_postgresql_flexible_server_configuration" "flexpsql" {
  count = length(keys(var.postgresql_configurations))

  name      = element(keys(var.postgresql_configurations), count.index)
  server_id = azurerm_postgresql_flexible_server.flexpsql.id
  value     = element(values(var.postgresql_configurations), count.index)
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
