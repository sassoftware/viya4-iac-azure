# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "private_ip_address" {
  value = azurerm_linux_virtual_machine.vm.private_ip_address
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}

output "public_ip_fqdn" {
  value = var.create_public_ip && var.public_ip_domain_name_label != null ? azurerm_public_ip.vm_ip[0].fqdn : null
}

output "admin_username" {
  value = azurerm_linux_virtual_machine.vm.admin_username
}
