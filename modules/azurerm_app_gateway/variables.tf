# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "A prefix used in the name for all the Azure resources created by this script."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Azure Application Gateway. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the Subnet which the Application Gateway should be connected to."
  type        = string
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
}

variable "sku" {
  description = "The Name of the SKU to use for this Application Gateway."
  type        = string
}

variable "port" {
  description = "The port which should be used for this Application Gateway."
  type        = string
}

variable "protocol" {
  description = "The Protocol which should be used. Possible values are Http and Https."
  type        = string
}

variable "backend_host_name" {
  description = "Host header to be sent to the backend servers."
  type        = string
  default     = null
}

variable "backend_trusted_root_certificate" {
  description = "The Trusted Root Certificate to use."
  type        = any
  default     = null
}

variable "ssl_certificate" {
  description = "The associated SSL Certificate which should be used for this HTTP Listener."
  type        = any
  default     = null
}

variable "backend_address_pool_fqdn" {
  description = "A list of FQDN's which should be part of the Backend Address Pool."
  type        = list(any)
}

variable "identity_ids" {
  description = "Specifies a list of User Assigned Managed Identity IDs to be assigned to this Application Gateway."
  type        = list(any)
  default     = null
}

variable "waf_policy_enabled" {
  description = "Is the Web Application Firewall enabled?"
  type        = bool
}

variable "waf_policy_config" {
  description = "Azure Web Application Firewall Policy instance configuration."
  type        = any
}

variable "probe" {
  description = "Health probes to be created for the Application Gateway."
  type        = any
}
