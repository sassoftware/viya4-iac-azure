variable "name" {
  description = "Name of the pre-existing vNet"
  default     = null
}

variable "prefix" {
  default = null
}

variable "location" {}

variable "resource_group_name" {
  description = "Name of the resource group to be imported."
  type        = string
}

variable "address_space" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
}

# If no values specified, this defaults to Azure DNS 
variable "dns_servers" {
  description = "The DNS servers to be used with vNet."
  type        = list(string)
  default     = []
}

variable "subnets" {
  type = map(object({
    prefixes                                       = list(string)
    service_endpoints                              = list(string)
    private_endpoint_network_policies_enabled      = bool
    private_link_service_network_policies_enabled  = bool
    service_delegations                            = map(object({
      name    = string
      actions = list(string)
    }))
  }))

  default = null
}

variable "existing_subnets" {
  type    = map(string)
  default = {}
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
}
