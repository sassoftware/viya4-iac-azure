# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

locals {
  rwx_filestore_endpoint = (var.storage_type == "none"
    ? ""
    : var.storage_type == "ha" ? module.netapp[0].netapp_endpoint : module.nfs[0].private_ip_address
  )

  rwx_filestore_path = (var.storage_type == "none"
    ? ""
    : var.storage_type == "ha" ? module.netapp[0].netapp_path : "/export"
  )

  jump_cloudconfig = var.create_jump_vm ? templatefile("${path.module}/files/cloud-init/jump/cloud-config", {
    mounts = (var.storage_type == "none"
      ? "[]"
      : jsonencode(
        ["${local.rwx_filestore_endpoint}:${local.rwx_filestore_path}",
          var.jump_rwx_filestore_path,
          "nfs",
          "_netdev,auto,x-systemd.automount,x-systemd.mount-timeout=10,timeo=14,x-systemd.idle-timeout=1min,relatime,hard,rsize=1048576,wsize=1048576,vers=3,tcp,namlen=255,retrans=2,sec=sys,local_lock=none",
          "0",
          "0"
      ])
    )
    rwx_filestore_endpoint  = local.rwx_filestore_endpoint
    rwx_filestore_path      = local.rwx_filestore_path
    jump_rwx_filestore_path = var.jump_rwx_filestore_path
    vm_admin                = var.jump_vm_admin
  }) : null

  nfs_cloudconfig = var.storage_type == "standard" ? templatefile("${path.module}/files/cloud-init/nfs/cloud-config", {
    aks_cidr_block  = module.vnet.subnets["aks"].address_prefixes[0]
    misc_cidr_block = module.vnet.subnets["misc"].address_prefixes[0]
    vm_admin        = var.nfs_vm_admin
  }) : null
}

data "cloudinit_config" "jump" {
  count = var.create_jump_vm ? 1 : 0

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = local.jump_cloudconfig
  }
}

module "jump" {
  source                      = "./modules/azurerm_vm"

  count                       = var.create_jump_vm ? 1 : 0
  name                        = "${var.prefix}-jump"
  azure_rg_name               = local.aks_rg.name
  azure_rg_location           = var.location
  vnet_subnet_id              = module.vnet.subnets["misc"].id
  machine_type                = var.jump_vm_machine_type
  azure_nsg_id                = local.nsg.id
  tags                        = var.tags
  vm_admin                    = var.jump_vm_admin
  vm_zone                     = var.jump_vm_zone
  fips_enabled                = var.fips_enabled
  ssh_public_key              = local.ssh_public_key
  cloud_init                  = data.cloudinit_config.jump[0].rendered
  create_public_ip            = var.create_jump_public_ip
  public_ip_allocation_method = var.jump_public_ip_allocation_method
  public_ip_domain_name_label = var.jump_public_ip_domain_name_label


  # Jump VM mounts NFS path hence dependency on 'module.nfs'
  depends_on                  = [module.vnet, module.nfs]
}

data "cloudinit_config" "nfs" {
  count = var.storage_type == "standard" ? 1 : 0

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = local.nfs_cloudconfig
  }
}

module "nfs" {
  source = "./modules/azurerm_vm"

  count                          = var.storage_type == "standard" ? 1 : 0
  name                           = "${var.prefix}-nfs"
  azure_rg_name                  = local.aks_rg.name
  azure_rg_location              = var.location
  proximity_placement_group_id   = element(coalescelist(azurerm_proximity_placement_group.proximity[*].id, [""]), 0)
  vnet_subnet_id                 = module.vnet.subnets["misc"].id
  machine_type                   = var.nfs_vm_machine_type
  azure_nsg_id                   = local.nsg.id
  tags                           = var.tags
  vm_admin                       = var.nfs_vm_admin
  vm_zone                        = var.nfs_vm_zone
  fips_enabled                   = var.fips_enabled
  ssh_public_key                 = local.ssh_public_key
  cloud_init                     = data.cloudinit_config.nfs[0].rendered
  create_public_ip               = var.create_nfs_public_ip
  public_ip_allocation_method    = var.nfs_public_ip_allocation_method
  public_ip_domain_name_label    = var.nfs_public_ip_domain_name_label
  data_disk_count                = 4
  data_disk_size                 = var.nfs_raid_disk_size
  data_disk_storage_account_type = var.nfs_raid_disk_type
  data_disk_zone                 = var.nfs_raid_disk_zone
  depends_on                     = [module.vnet]
}

resource "azurerm_network_security_rule" "vm-ssh" {
  name        = "${var.prefix}-ssh"
  description = "Allow SSH from source"
  count = (length(local.vm_public_access_cidrs) > 0
    && ((var.create_jump_public_ip && var.create_jump_vm) || (var.create_nfs_public_ip && var.storage_type == "standard"))
    ? 1 : 0
  )
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = local.vm_public_access_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = local.nsg_rg_name
  network_security_group_name = local.nsg.name
}
