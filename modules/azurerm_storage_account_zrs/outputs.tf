# Copyright © 2020-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.zrs.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.zrs.name
}

output "primary_file_endpoint" {
  description = "Primary file service endpoint"
  value       = azurerm_storage_account.zrs.primary_file_endpoint
}

output "primary_file_host" {
  description = "Primary file service host"
  value       = azurerm_storage_account.zrs.primary_file_host
}

output "share_name" {
  description = "Name of the NFS file share"
  value       = azurerm_storage_share.viya.name
}

output "share_url" {
  description = "URL of the file share"
  value       = azurerm_storage_share.viya.url
}

output "nfs_mount_path" {
  description = "NFS mount path for Kubernetes storage class"
  value       = "${azurerm_storage_account.zrs.name}.file.core.windows.net:/${azurerm_storage_account.zrs.name}/${azurerm_storage_share.viya.name}"
}

output "private_endpoint_ip" {
  description = "Private IP address of the storage account (if private endpoint is created)"
  value       = var.create_private_endpoint ? azurerm_private_endpoint.storage[0].private_service_connection[0].private_ip_address : null
}

output "private_endpoint_id" {
  description = "ID of the private endpoint (if created)"
  value       = var.create_private_endpoint ? azurerm_private_endpoint.storage[0].id : null
}
