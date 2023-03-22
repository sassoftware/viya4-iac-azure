# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "resource_group_name" {
  description = "The name of the Resource Group where the PostgreSQL Flexible Server should exist. Changing this forces a new PostgreSQL Flexible Server to be created."
  type        = string
}

variable "location" {
  description = "The Azure Region where the PostgreSQL Flexible Server should exist. Changing this forces a new PostgreSQL Flexible Server to be created."
  type        = string
}

variable "server_name" {
  description = "The name which should be used for this PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created."
  type        = string
}

variable "sku_name" {
  description = "The SKU Name for the PostgreSQL Flexible Server. The name of the SKU, follows the tier + name pattern (e.g. B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3)."
  type        = string
  default     = "GP_Standard_D16s_v3"
}

variable "storage_mb" {
  description = "The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432."
  type        = number
  default     = 65536
}

variable "backup_retention_days" {
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enables Geo-Redundant backup on the PostgreSQL Flexible Server. Defaults to false. Changing this forces a new PostgreSQL Flexible Server to be created."
  type        = bool
  default     = false
}

variable "administrator_login" {
  description = " The Administrator login for the PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created."
  type        = string
}

variable "administrator_password" {
  description = "The Password associated with the administrator_login for the PostgreSQL Flexible Server."
  type        = string
}

variable "server_version" {
  description = "Specifies the version of PostgreSQL to use. The version of PostgreSQL Flexible Server to use. Possible values are 11, 12 and 13. Changing this forces a new PostgreSQL Flexible Server to be created."
  type        = string
  default     = "13"
}

variable "public_network_access_enabled" {
  description = "Whether or not public network access is allowed for this server. Defaults to true"
  type        = bool
  default     = true
}

variable "firewall_rule_prefix" {
  description = "Specifies prefix for firewall rule names."
  type        = string
  default     = "firewall-"
}

variable "firewall_rules" {
  description = "The list of maps, describing firewall rules. Valid map items: name, start_ip, end_ip."
  type        = list(map(string))
  default     = []
}

variable "tags" {
  description = "A map of tags to set on every taggable resources. Empty by default."
  type        = map(string)
  default     = {}
}

variable "postgresql_configurations" {
  description = "A map with PostgreSQL configurations to enable."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "virtual_network_id" {
  description = "The ID of the Virtual Network that should be linked to the DNS Zone. Changing this forces a new resource to be created."
  type        = string
}

variable "delegated_subnet_id" {
  description = "Subnet Id"
  type        = string
}

# variable "private_dns_zone_id" {
#   description = "The ID of the private DNS zone to create the PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created."
#   type        = string
# }
