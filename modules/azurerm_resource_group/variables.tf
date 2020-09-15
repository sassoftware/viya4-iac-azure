variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
 }

variable "azure_rg_name" {
  description = "Resource group name"
}

variable "azure_rg_location" {
  description = "Resource group location"
}