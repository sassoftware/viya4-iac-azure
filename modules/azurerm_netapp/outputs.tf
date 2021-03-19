output "netapp_subnet" {
  value = azurerm_subnet.anf.name
}

output "netapp_account_id" {
  value = azurerm_netapp_account.anf.id
}

output "netapp_pool_id" {
  value = azurerm_netapp_pool.anf.id
}

output "netapp_export_rule_cidr" {
  value = var.subnet_address_prefix
}

output "netapp_endpoint" {
  value = azurerm_netapp_volume.anf.mount_ip_addresses.0
}

output "netapp_path" {
  value = "/${var.volume_path}"
}
