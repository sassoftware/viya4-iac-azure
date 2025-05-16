# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# https://docs.microsoft.com/en-us/azure/virtual-network/public-ip-addresses
resource "azurerm_public_ip" "vm_ip" {
  count               = var.create_public_ip ? 1 : 0
  name                = "${var.name}-public_ip"
  location            = var.azure_rg_location
  resource_group_name = var.azure_rg_name
  allocation_method   = var.enable_public_static_ip ? "Static" : "Dynamic"
  sku                 = "Standard"
  zones               = var.vm_zone == null ? [] : [var.vm_zone]
  tags                = var.tags
}

resource "azurerm_network_interface" "vm_nic" {
  name                           = "${var.name}-nic"
  location                       = var.azure_rg_location
  resource_group_name            = var.azure_rg_name
  accelerated_networking_enabled = length(regexall("-nfs", var.name)) > 0 ? true : var.accelerated_networking_enabled

  ip_configuration {
    name                          = "${var.name}-ip_config"
    subnet_id                     = var.vnet_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.vm_ip[0].id : null
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "vm_nic_sg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = var.azure_nsg_id
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk
resource "azurerm_managed_disk" "vm_data_disk" {
  count                  = var.data_disk_count
  name                   = format("%s-disk%02d", var.name, count.index + 1)
  location               = var.azure_rg_location
  resource_group_name    = var.azure_rg_name
  storage_account_type   = var.data_disk_storage_account_type
  create_option          = "Empty"
  disk_size_gb           = var.data_disk_size
  zone                   = var.data_disk_zone
  disk_encryption_set_id = var.disk_encryption_set_id
  tags                   = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm_data_disk_attach" {
  count              = var.data_disk_count
  managed_disk_id    = azurerm_managed_disk.vm_data_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = count.index + 10
  caching            = var.data_disk_storage_account_type == "UltraSSD_LRS" ? "None" : var.data_disk_caching
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                         = "${var.name}-vm"
  location                     = var.azure_rg_location
  proximity_placement_group_id = var.proximity_placement_group_id == "" ? null : var.proximity_placement_group_id
  resource_group_name          = var.azure_rg_name
  size                         = var.machine_type
  admin_username               = var.vm_admin
  zone                         = var.vm_zone
  encryption_at_host_enabled   = var.encryption_at_host_enabled

  #Cloud Init
  custom_data = (var.cloud_init != "" ? var.cloud_init : null)

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = var.vm_admin
    public_key = var.ssh_public_key
  }

  os_disk {
    caching                = var.os_disk_caching
    storage_account_type   = var.os_disk_storage_account_type
    disk_size_gb           = var.os_disk_size
    disk_encryption_set_id = var.disk_encryption_set_id
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.fips_enabled ? "0001-com-ubuntu-pro-jammy-fips" : var.os_offer
    sku       = var.fips_enabled ? "pro-fips-22_04-gen2" : var.os_sku
    version   = var.os_version
  }

  dynamic "plan" {
    for_each = var.fips_enabled ? [1] : []
    content {
      name      = "pro-fips-22_04-gen2"
      publisher = "canonical"
      product   = "0001-com-ubuntu-pro-jammy-fips"
    }
  }

  additional_capabilities {
    ultra_ssd_enabled = var.data_disk_storage_account_type == "UltraSSD_LRS" ? true : false
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [ identity ]
  }

  depends_on = [azurerm_network_interface_security_group_association.vm_nic_sg]
}
