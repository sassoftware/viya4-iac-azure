# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

###################################################
### Managed PostgreSQL Flexible server on Azure ###
###################################################

## https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server

resource "azurerm_private_dns_zone" "flexpsql" {
  count = var.connectivity_method == "private" ? 1 : 0

  name                = "${var.server_name}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "flexpsql" {
  count = var.connectivity_method == "private" ? 1 : 0

  name                  = var.server_name
  private_dns_zone_name = azurerm_private_dns_zone.flexpsql[0].name
  virtual_network_id    = var.virtual_network_id
  resource_group_name   = var.resource_group_name
}

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
  delegated_subnet_id          = var.delegated_subnet_id
  private_dns_zone_id          = try(azurerm_private_dns_zone.flexpsql[0].id, null)

  depends_on = [azurerm_private_dns_zone_virtual_network_link.flexpsql]

  lifecycle {
    ignore_changes = [
      # Ignore changes to zone on updates after intial creation
      zone
    ]
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "flexpsql" {
  for_each = {
    for config in var.postgresql_configurations :
    config.name => config
  }

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.flexpsql.id
  value     = each.value.value
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "flexpsql" {
  count = var.connectivity_method == "public" ? length(var.firewall_rules) : 0

  name             = format("%s%s", var.firewall_rule_prefix, lookup(var.firewall_rules[count.index], "name", count.index))
  server_id        = azurerm_postgresql_flexible_server.flexpsql.id
  start_ip_address = var.firewall_rules[count.index]["start_ip"]
  end_ip_address   = var.firewall_rules[count.index]["end_ip"]
}

# NOTE: This firewall rule enables the flag - "Allow public access from any Azure service within Azure to this server"
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_public" {
  count = var.connectivity_method == "public" ? 1 : 0

  name             = "Allow-public-access-from-any-Azure-service"
  server_id        = azurerm_postgresql_flexible_server.flexpsql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
