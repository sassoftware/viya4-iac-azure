# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
# MULTI-AZ ENHANCED VERSION - Compare with variables.tf

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
  description = "The SKU Name for the PostgreSQL Flexible Server. The name of the SKU, follows the tier + name pattern (e.g. B_Standard_B1ms, GP_Standard_D2s_v5, MO_Standard_E4s_v5)."
  type        = string
  default     = "GP_Standard_D4s_v5"
}

variable "storage_mb" {
  description = "The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432."
  type        = number
  default     = 131072
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
  description = "Specifies the version of PostgreSQL to use. The version of PostgreSQL Flexible Server to use. Possible values are 11, 12, 13, 14, 15, and 16. Changing this forces a new PostgreSQL Flexible Server to be created."
  type        = string
  default     = "15"
}

variable "connectivity_method" {
  description = "Network connectivity options to connect to your flexible server. Valid options are 'public' and 'private'. Defaults to public"
  type        = string
  default     = "public"
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
  description = "The ID of the virtual network subnet to create the PostgreSQL Flexible Server. The provided subnet should not have any other resource deployed in it and this subnet will be delegated to the PostgreSQL Flexible Server, if not already delegated. Changing this forces a new PostgreSQL Flexible Server to be created."
  type        = string
}

# ✅ NEW: Multi-AZ Variables
variable "availability_zone" {
  description = "The availability zone for the primary PostgreSQL Flexible Server. Values: '1', '2', or '3'"
  type        = string
  default     = "1"
  
  validation {
    condition     = var.availability_zone == null || contains(["1", "2", "3"], var.availability_zone)
    error_message = "Availability zone must be '1', '2', '3', or null."
  }
}

variable "high_availability_mode" {
  description = "High availability mode. Valid values: 'ZoneRedundant' (standby in different zone), 'SameZone' (standby in same zone), or null to disable HA"
  type        = string
  default     = null
  
  validation {
    condition     = var.high_availability_mode == null || contains(["ZoneRedundant", "SameZone"], var.high_availability_mode)
    error_message = "Valid values are: 'ZoneRedundant', 'SameZone', or null."
  }
}

variable "standby_availability_zone" {
  description = "The availability zone for the standby server. Must be different from availability_zone when using ZoneRedundant mode."
  type        = string
  default     = "2"
  
  validation {
    condition     = var.standby_availability_zone == null || contains(["1", "2", "3"], var.standby_availability_zone)
    error_message = "Standby availability zone must be '1', '2', '3', or null."
  }
  
  validation {
    condition     = var.high_availability_mode != "ZoneRedundant" || (var.standby_availability_zone != null && var.standby_availability_zone != var.availability_zone)
    error_message = "When high_availability_mode is 'ZoneRedundant', standby_availability_zone must be set and differ from availability_zone to ensure proper zone-redundant high availability."
  }
}
