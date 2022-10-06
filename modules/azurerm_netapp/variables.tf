
variable create_netapp {
  description = "Boolean flag to create Azure NetApp Files"
  default     = false
}
variable "prefix" {
  description = "A prefix used in the name for all the Azure resources created by this script."
}

variable resource_group_name {
  description = "The name of the resource group in which to create Azure NetApp Files storage"
}

variable "location" {
  description = "The Azure Region to provision all resources in this script"
}

variable "vnet_name" {
  description = "Azure Virtual Network"
}

variable "subnet_id" {
  description = "Azure subnet id for Azure NetApp Files"
}

variable "network_features" {
  description = "Indicates which network feature to use, accepted values are Basic or Standard, it defaults to Basic if not defined."
}

# https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-service-levels
variable "service_level" {
  description = "The target performance of the file system. Valid values include Premium, Standard, or Ultra."
}
variable "size_in_tb" {
  description = "Provisioned size of the pool in TB. Value must be between 4 and 500"
}

variable "volume_path" {
  description = "A unique file path for the volume. Used when creating mount targets. Changing this forces a new resource to be created"
}
variable "protocols" {
  description = "The target volume protocol expressed as a list. Supported single value include CIFS, NFSv3, or NFSv4.1. If argument is not defined it will default to NFSv3. Changing this forces a new resource to be created and data will be lost."
  default     = ["NFSv3"]
}

variable "allowed_clients" {
  description = "CIDR blocks allowed to mount nfs exports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
}
