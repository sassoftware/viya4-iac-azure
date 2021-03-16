output "private_ip_address" {
  value = azurerm_linux_virtual_machine.vm.private_ip_address
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.vm.public_ip_address
}

output "admin_username" {
  value = azurerm_linux_virtual_machine.vm.admin_username
}
