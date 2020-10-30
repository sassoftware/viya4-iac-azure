output "private_ip_address" {
  value = var.create_vm ? element(coalescelist(azurerm_linux_virtual_machine.vm.*.private_ip_address, [""]), 0) : null
}

output "public_ip_address" {
  value = var.create_vm ? element(coalescelist(azurerm_linux_virtual_machine.vm.*.public_ip_address, [""]), 0) : null
}

output "admin_username" {
  value = var.create_vm ? element(coalescelist(azurerm_linux_virtual_machine.vm.*.admin_username, [var.vm_admin]), 0) : null
}

output "private_key_pem" {
  value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.private_key_pem, [""]), 0) : null
}

output "public_key_pem" {
  value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.public_key_pem, [""]), 0) : null
}

output "public_key_openssh" {
  value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.public_key_openssh, [""]), 0) : null
}
