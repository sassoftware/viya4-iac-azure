variable "name" {
  description = "Name of the existing resource group"
  type        = string
  default     = null
}

variable "prefix" {
  type    = string
  default = null
}

variable "location" {
  description = "The Azure Region in which to provision resources"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The resource group in which to provision resources"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of common tags to be placed on the resources"
  type        = map(any)
  default     = {}
}
