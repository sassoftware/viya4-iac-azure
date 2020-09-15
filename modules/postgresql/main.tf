# Generate random password to be used if user did not provide
resource "random_password" "password" {
  length  = 32
  special = true
}

# Reference: https://www.terraform.io/docs/providers/azurerm/r/postgresql_server.html
resource "azurerm_postgresql_server" "server" {
  count               = var.create_postgres ? 1 : 0
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name                      = var.postgres_sku_name
  storage_mb                    = var.postgres_storage_mb
  backup_retention_days         = var.postgres_backup_retention_days
  geo_redundant_backup_enabled  = var.postgres_geo_redundant_backup_enabled
  administrator_login          = var.postgres_administrator_login
  administrator_login_password = var.postgres_administrator_password == null ? random_password.password.result : var.postgres_administrator_password
  version                      = var.postgres_server_version
  ssl_enforcement_enabled      = var.postgres_ssl_enforcement_enabled
  tags                         = var.tags

  # threat_detection_policy {
  #   enabled = false
  #   disabled_alerts      = []
  #   email_account_admins = false
  #   email_addresses      = []
  #   retention_days       = 0
  # }
}

resource "azurerm_postgresql_database" "dbs" {
  count               = var.create_postgres ? length(var.postgres_db_names) : 0
  name                = var.postgres_db_names[count.index]
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server[0].name
  charset             = var.postgres_db_charset
  collation           = var.postgres_db_collation

  depends_on = [azurerm_postgresql_server.server]
}

resource "azurerm_postgresql_firewall_rule" "postgres_firewall_rules" {
  count               = var.create_postgres ? length(var.postgres_firewall_rules) : 0
  name                = lookup(element(var.postgres_firewall_rules, count.index), "name", "AllAzureServices")
  resource_group_name = var.resource_group_name
  server_name         = var.server_name #azurerm_postgresql_server.server[0].name
  start_ip_address    = lookup(element(var.postgres_firewall_rules, count.index), "start_ip", "0.0.0.0")
  end_ip_address      = lookup(element(var.postgres_firewall_rules, count.index), "end_ip", "0.0.0.0")

  depends_on = [azurerm_postgresql_server.server]
}

resource "azurerm_postgresql_virtual_network_rule" "postgres_vnet_rules" {
  count               = var.create_postgres ? length(var.postgres_vnet_rules) : 0
  name                = "${var.postgres_vnet_rule_prefix}${lookup(var.postgres_vnet_rules[count.index], "name", count.index)}"
  resource_group_name = var.resource_group_name
  server_name         = var.server_name #azurerm_postgresql_server.server[0].name
  subnet_id           = lookup(var.postgres_vnet_rules[count.index], "subnet_id")
  ignore_missing_vnet_service_endpoint = true

  depends_on = [azurerm_postgresql_server.server]
}

resource "azurerm_postgresql_configuration" "db_configs" {
  count               = var.create_postgres ? length(keys(var.postgres_configurations)) : 0
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.server[0].name
  name                = element(keys(var.postgres_configurations), count.index)
  value               = element(values(var.postgres_configurations), count.index)

  depends_on = [azurerm_postgresql_server.server]
}
