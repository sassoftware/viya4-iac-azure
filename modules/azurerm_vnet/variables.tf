variable "name" {
  description = "Name of the pre-existing VNet"
  type        = string
  default     = null
}

variable "prefix" {
  description = "A prefix to be used in resources creation"
  type        = string
  default     = null
}

variable "location" {
  description = "The Azure Region to provision the Virtual Network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to be imported."
  type        = string
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = list(string)
}

# If no values specified, this defaults to Azure DNS 
variable "dns_servers" {
  description = "The DNS servers to be used with vNet."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Subnets to be created and their settings"
  type = map(object({
    prefixes                                      = list(string)
    service_endpoints                             = list(string)
    private_endpoint_network_policies_enabled     = bool
    private_link_service_network_policies_enabled = bool
    service_delegations = map(object({
      name    = string
      actions = list(string)
    }))
  }))

  default = null
}

variable "existing_subnets" {
  description = "Set of existing subnets"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
}
