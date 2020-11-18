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
  type        = map
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

variable "ssh_public_key" {
  description = "Path to ssh public key"
  default     = ""
}

variable "os_publisher" {
  default = "OpenLogic"
}

variable "os_offer" {
  default = "CentOS"
}

variable "os_sku" {
  default = "7_8"
}

variable "os_version" {
  default = "latest"
}

variable name {
  type = string
}

variable data_disk_count {
  default = 0
}

variable data_disk_size {
  default = 128
}

variable data_disk_caching {
  default = "ReadWrite"
}

variable os_disk_size {
  default = 64
}

variable os_disk_caching {
  default = "ReadOnly"
}

variable enable_accelerated_networking {
  default = true
}

variable create_vm {
  default = false
}

variable cloud_init {
  default = ""
}

variable create_public_ip {
  default = false
}

variable "proximity_placement_group_id" {
  type    = string
  default = ""
}
