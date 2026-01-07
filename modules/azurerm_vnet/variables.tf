# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

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

variable "ipv6_address_space" {
  description = "The IPv6 address space that is used by the virtual network. Must be /48 CIDR block."
  type        = list(string)
  default     = null
}

variable "enable_ipv6" {
  description = "Enable IPv6 dual-stack configuration planning. NOTE: Actual IPv6 subnet prefix allocation requires manual configuration via Azure CLI/Portal or the azapi provider, as the Terraform azurerm provider does not yet support ipv6_address_prefix on subnets."
  type        = bool
  default     = false
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
    private_endpoint_network_policies             = string
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

variable "roles" {
    description = "Managed Identity permissions for VNet and Route Table"
    type = list(string)
    default = ["Network Contributor"]
}

variable "aks_uai_principal_id" {
  description = "Managed Identity Principal ID used to associate permissions to network and route table"
  type = string
}

variable "add_uai_permissions" {
  description = "True if we should add roles to network objects"
  default = false
  type = bool
}
