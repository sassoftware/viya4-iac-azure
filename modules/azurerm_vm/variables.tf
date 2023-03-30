# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "azure_rg_name" {
  description = "The name of the Resource Group where the VM should exist."
  type        = string
}

variable "azure_rg_location" {
  description = "The name of the Resource Group location where the VM should exist."
  type        = string
}

variable "azure_nsg_id" {
  description = "The ID of the Network Security Group."
  type        = string
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
}

variable "vnet_subnet_id" {
  description = "The ID of the Subnet. Changing this forces a new resource to be created."
  type        = string
}

variable "machine_type" {
  description = "The size which should be used for this Virtual Machine, such as Standard_F2."
  type        = string
  default     = "Standard_E8s_v3"
}

variable "vm_admin" {
  description = "OS Admin User for VMs of AKS Cluster nodes"
  type        = string
  default     = "azureuser"
}

variable "vm_zone" {
  description = "The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created"
  type        = string
  default     = null
}

variable "fips_enabled" {
  description = "Should the nodes in this Node Pool have Federal Information Processing Standard enabled? Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  type        = string
  default     = ""
}

variable "os_publisher" {
  description = "Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created."
  type        = string
  default     = "Canonical"
}

variable "os_offer" {
  description = "Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created."
  type        = string
  default     = "0001-com-ubuntu-server-focal"
}

variable "os_sku" {
  description = "Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created."
  type        = string
  default     = "20_04-lts"
}

variable "os_version" {
  description = "Specifies the version of the image used to create the virtual machines. Changing this forces a new resource to be created."
  type        = string
  default     = "latest"
}

variable "name" {
  description = "VM name"
  type        = string
}

variable "data_disk_count" {
  description = "Number of disks to be created"
  type        = number
  default     = 0
}

variable "data_disk_size" {
  description = "Specifies the size of the managed disk to create in GB."
  type        = number
  default     = 128
}

variable "data_disk_caching" {
  description = "Specifies the caching requirements for this Data Disk. Possible values include None, ReadOnly and ReadWrite"
  type        = string
  default     = "ReadWrite"
}

variable "data_disk_storage_account_type" {
  description = "The type of storage to use for the managed disk. Possible values are Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS."
  type        = string
  default     = "Standard_LRS"
}

variable "data_disk_zone" {
  description = "Specifies the Availability Zone in which this Managed Disk should be located. Changing this property forces a new resource to be created."
  type        = string
  default     = null
}

variable "os_disk_size" {
  description = "The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from."
  type        = number
  default     = 64
}

variable "os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values are Standard_LRS, StandardSSD_LRS and Premium_LRS. Changing this forces a new resource to be created"
  type        = string
  default     = "Standard_LRS"
}

variable "os_disk_caching" {
  description = "The Type of Caching which should be used for the Internal OS Disk. Possible values are None, ReadOnly and ReadWrite."
  type        = string
  default     = "ReadOnly"
}

variable "enable_accelerated_networking" {
  description = "Enables network accelaration for VMs. By default enabled for the nfs and jump VMs. For any other VM the default is false"
  type        = bool
  default     = false
}

variable "cloud_init" {
  description = "cloud_init config"
  type        = string
  default     = ""
}

variable "create_public_ip" {
  description = "If true associates a Public IP Address to the NIC"
  type        = bool
  default     = false
}

variable "proximity_placement_group_id" {
  description = "The ID of the Proximity Placement Group which the Virtual Machine should be assigned to."
  type        = string
  default     = ""
}
