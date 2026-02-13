# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "A prefix used in the name for all the Azure resources created by this script."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create Azure NetApp Files storage"
  type        = string
}

variable "location" {
  description = "The Azure Region to provision all resources in this script"
  type        = string
}

variable "subnet_id" {
  description = "Azure subnet id for Azure NetApp Files"
  type        = string
}

variable "network_features" {
  description = "Indicates which network feature to use, accepted values are `Basic` or `Standard`, it defaults to `Basic` if not defined."
  type        = string
  default     = "Basic"
  
  validation {
    condition     = !var.netapp_enable_cross_zone_replication || var.network_features == "Standard"
    error_message = "When netapp_enable_cross_zone_replication is enabled, network_features must be set to 'Standard'. Cross-zone replication requires Standard network features."
  }
}

# https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-service-levels
variable "service_level" {
  description = "The target performance of the file system. Valid values include Premium, Standard, or Ultra."
  type        = string
}

variable "size_in_tb" {
  description = "Provisioned size of the pool in TB. Value must be between 1 and 2048"
  type        = number
}

variable "volume_path" {
  description = "A unique file path for the volume. Used when creating mount targets. Changing this forces a new resource to be created"
  type        = string
}

variable "protocols" {
  description = "The target volume protocol expressed as a list. Supported single value include CIFS, NFSv3, or NFSv4.1. If argument is not defined it will default to NFSv4.1. Changing this forces a new resource to be created and data will be lost."
  type        = list(string)
  default     = ["NFSv4.1"]
}

variable "allowed_clients" {
  description = "CIDR blocks allowed to mount nfs exports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map(any)
}

# Community Contribution
# Netapp Volume Size control
variable "community_netapp_volume_size" {
  description = "Community Contributed field. Will manually set the value of the Netapp Volume smaller than the Netapp Pool. This value is in GB."
  type = number
  default = 0
}

# Multi-AZ Variables
variable "netapp_availability_zone" {
  description = "Primary availability zone for Azure NetApp Files volume. Set to '1', '2', or '3' for zonal deployment."
  type        = string
  nullable    = true
  default     = "1"
  
  validation {
    condition     = var.netapp_availability_zone == null || contains(["1", "2", "3"], var.netapp_availability_zone)
    error_message = "NetApp availability zone must be '1', '2', '3', or null."
  }
}

variable "netapp_enable_cross_zone_replication" {
  description = "Enable cross-zone replication for Azure NetApp Files to ensure zone failure resilience. Requires Standard network features."
  type        = bool
  default     = false
}

variable "netapp_replication_zone" {
  description = "Target availability zone for NetApp cross-zone replication. Must be different from netapp_availability_zone."
  type        = string
  nullable    = true
  default     = "2"
  
  validation {
    condition     = var.netapp_replication_zone == null || contains(["1", "2", "3"], var.netapp_replication_zone)
    error_message = "NetApp replication zone must be '1', '2', '3', or null."
  }
  
  validation {
    condition     = !var.netapp_enable_cross_zone_replication || (var.netapp_replication_zone != null && var.netapp_replication_zone != var.netapp_availability_zone)
    error_message = "When netapp_enable_cross_zone_replication is enabled, netapp_replication_zone must be set and differ from netapp_availability_zone to ensure proper cross-zone replication."
  }
}

variable "netapp_replication_frequency" {
  description = "Replication frequency for cross-zone replication. Valid values: 10minutes, hourly, daily"
  type        = string
  default     = "10minutes"
  
  validation {
    condition     = contains(["10minutes", "hourly", "daily"], var.netapp_replication_frequency)
    error_message = "Valid values are: 10minutes, hourly, daily."
  }
}
