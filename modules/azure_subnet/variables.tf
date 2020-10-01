variable name {
  description = "Name"
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
}

variable "azure_rg_name" {
  description = "Existing resource group name"
}

variable "azure_rg_location" {
  description = "Existing resource group location"
}

variable "service_endpoints" {
  default = ["Microsoft.Storage", "Microsoft.AzureActiveDirectory", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.Sql"]
}

variable "nsg" {
  default     = null
  description = "Existing Network Security Group"
}

variable "vnet_name" {
  description = "Existing vnet name"
}

variable "address_prefixes" {
  type        = list
  description = "Desired subnet cidrs"
}

