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
  description = "The Azure Region to provision resources"
  default     = "East US"
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = {}
}