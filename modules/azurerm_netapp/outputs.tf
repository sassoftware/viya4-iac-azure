# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "netapp_account_id" {
  value = var.community_netapp_account == "" ? azurerm_netapp_account.anf[0].id : null
}

output "netapp_pool_id" {
  value = var.community_netapp_pool == "" ? azurerm_netapp_pool.anf[0].id : null
}

output "netapp_endpoint" {
  value = azurerm_netapp_volume.anf.mount_ip_addresses[0]
}

output "netapp_path" {
  value = "/${var.volume_path}"
}
