output "private_ip_address" {
  value = var.create_vm ? element(coalescelist(azurerm_linux_virtual_machine.vm.*.private_ip_address, [""]), 0) : null
}

output "public_ip_address" {
  value = var.create_vm ? element(coalescelist(azurerm_linux_virtual_machine.vm.*.public_ip_address, [""]), 0) : null
}

output "admin_username" {
  value = var.create_vm ? element(coalescelist(azurerm_linux_virtual_machine.vm.*.admin_username, [var.vm_admin]), 0) : null
}
