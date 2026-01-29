# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "netapp_account_id" {
  value = azurerm_netapp_account.anf.id
}

output "netapp_pool_id" {
  value = azurerm_netapp_pool.anf.id
}

output "netapp_endpoint" {
  value = azurerm_netapp_volume.anf.mount_ip_addresses[0]
}

output "netapp_path" {
  value = "/${var.volume_path}"
}

# CZR DNS outputs
output "netapp_dns_hostname" {
  description = "Stable DNS hostname for NFS when CZR is enabled. Use this in storage class instead of static IP."
  value       = var.netapp_enable_cross_zone_replication ? "${var.netapp_dns_record_name}.${var.netapp_dns_zone_name}" : null
}

output "netapp_dns_zone_id" {
  description = "Private DNS Zone ID for ANF CZR"
  value       = var.netapp_enable_cross_zone_replication ? azurerm_private_dns_zone.anf_dns[0].id : null
}

output "netapp_dns_record_id" {
  description = "DNS A record ID pointing to primary ANF volume"
  value       = var.netapp_enable_cross_zone_replication ? azurerm_private_dns_a_record.anf_primary[0].id : null
}
