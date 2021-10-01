variable "azure_rg_name" {
  type = string
}

variable "azure_rg_location" {
  type = string
}

variable "azure_nsg_id" {
  type = string
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
}

variable "vnet_subnet_id" {
  type = string
}

variable "machine_type" {
  default = "Standard_E8s_v3"
}

variable "vm_admin" {
  description = "OS Admin User for VMs of AKS Cluster nodes"
  default     = "azureuser"
}

variable "vm_zone" {
  description = "The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created"
  default     = null
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  default     = ""
}

variable "os_publisher" {
  default = "Canonical"
}

variable "os_offer" {
  default = "0001-com-ubuntu-server-focal"
}

variable "os_sku" {
  default = "20_04-lts"
}

variable "os_version" {
  default = "latest"
}

variable "name" {
  type = string
}

variable "data_disk_count" {
  default = 0
}

variable "data_disk_size" {
  default = 128
}

variable "data_disk_caching" {
  default = "ReadWrite"
}

variable "data_disk_storage_account_type" {
  default     = "Standard_LRS"
  description = "The type of storage to use for the managed disk. Possible values are Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS."
}

variable "data_disk_zones" {
  description = "A collection containing the availability zone to allocate the Managed Disk in."
  default     = []
}

variable "os_disk_size" {
  default = 64
}

variable "os_disk_storage_account_type" {
  default     = "Standard_LRS"
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values are Standard_LRS, StandardSSD_LRS and Premium_LRS. Changing this forces a new resource to be created"
}

variable "os_disk_caching" {
  default = "ReadOnly"
}

variable "enable_accelerated_networking" {
  default = false
}

variable "create_vm" {
  default = false
}

variable "cloud_init" {
  default = ""
}

variable "create_public_ip" {
  default = false
}

variable "proximity_placement_group_id" {
  type    = string
  default = ""
}
