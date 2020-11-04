# Reference: https://github.com/terraform-providers/terraform-provider-azurerm
resource "azurerm_public_ip" "vm_ip" {
  count               = var.create_public_ip ? 1 : 0
  name                = "${var.name}-public_ip"
  location            = var.azure_rg_location
  resource_group_name = var.azure_rg_name
  allocation_method   = "Static"
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_network_interface" "vm_nic" {
  count                         = var.create_vm ? 1 : 0
  name                          = "${var.name}-nic"
  location                      = var.azure_rg_location
  resource_group_name           = var.azure_rg_name
  enable_accelerated_networking = var.enable_accelerated_networking

  ip_configuration {
    name                          = "${var.name}-ip_config"
    subnet_id                     = var.vnet_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.vm_ip.0.id : null
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "vm_nic_sg" {
  count                     = var.create_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.vm_nic.0.id
  network_security_group_id = var.azure_nsg_id
}

resource "azurerm_managed_disk" "vm_data_disk" {
  name                 = format("%s-disk%02d", var.name, count.index + 1)
  location             = var.azure_rg_location
  resource_group_name  = var.azure_rg_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size
  count                = var.create_vm ? var.data_disk_count : 0
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm_data_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.vm_data_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.0.id
  lun                = count.index + 10
  caching            = var.data_disk_caching
  count              = var.create_vm ? var.data_disk_count : 0
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.create_vm ? 1 : 0
  name                = "${var.name}-vm"
  location            = var.azure_rg_location
  resource_group_name = var.azure_rg_name
  size                = var.machine_type
  admin_username      = var.vm_admin

  #Cloud Init
  custom_data = (var.cloud_init != "" ? var.cloud_init : null)

  network_interface_ids = [
    azurerm_network_interface.vm_nic.0.id,
  ]

  admin_ssh_key {
    username   = var.vm_admin
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }

  tags = var.tags
}

# resource "local_file" "local_file_private_key_pem" {
#   content  = data.tls_public_key.public_key.private_key_pem
#   filename = "${path.root}/${var.name}-private_key.pem"
#   file_permission = "0700"
# }
