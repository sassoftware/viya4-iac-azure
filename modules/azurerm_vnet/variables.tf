variable "name" {
  description = "Name of the pre-existing vNet"
  default     = ""
}

variable "prefix" {
  default = ""
}

variable "location" {}

variable "resource_group_name" {
  description = "Name of the resource group to be imported."
  type        = string
  default = "vnetst-rg"
}

variable "address_space" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
  default     = ["10.0.0.0/16"]
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
    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool
    service_delegations                            = map(object({
      name    = string
      actions = list(string)
    }))
  }))

  default = null
}

variable "existing_subnets" {
  type    = map(string)
  default = null
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
}
