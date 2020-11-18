output "netapp_subnet" {
  value = var.create_netapp ? element(coalescelist(azurerm_subnet.anf.*.name, [" "]), 0) : null
}

output "netapp_account_id" {
  value = var.create_netapp ? element(coalescelist(azurerm_netapp_account.anf.*.id, [""]), 0) : null
}

output "netapp_pool_id" {
  value = var.create_netapp ? element(coalescelist(azurerm_netapp_pool.anf.*.id, [""]), 0) : null
}

output "netapp_export_rule_cidr" {
  value = var.create_netapp ? element(coalescelist(var.subnet_address_prefix, [""]), 0) : null
}

output "netapp_endpoint" {
  value = var.create_netapp ? element(coalescelist(azurerm_netapp_volume.anf.*.mount_ip_addresses.0, [""]), 0) : null
}

output "netapp_path" {
  value = var.create_netapp ? "/${var.volume_path}" : null
}