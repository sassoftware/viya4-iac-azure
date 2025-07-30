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
}

# https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-service-levels
variable "service_level" {
  description = "The target performance of the file system. Valid values include Premium, Standard, or Ultra."
  type        = string
}

variable "size_in_tb" {
  description = "Provisioned size of the pool in TB. Value must be between 4 and 500"
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

# Netapp BYO Components
variable "community_netapp_account" {
  description = "Community Contributed field. Will manually set the Netapp Account for Netapp components."
  type = string
  default = ""
}

variable "community_netapp_pool" {
  description = "Community Contributed field. Will manually set the Netapp Pool for Netapp components."
  type = string
  default = ""
}