# Copyright © 2020-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 lowercase letters/numbers)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the storage account"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier. Valid values: 'Standard', 'Premium'"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be 'Standard' or 'Premium'."
  }
}

variable "share_name" {
  description = "Name of the NFS file share"
  type        = string
  default     = "viya"
}

variable "quota_gb" {
  description = "Quota in GB for the file share"
  type        = number
  default     = 5120

  validation {
    condition     = var.quota_gb >= 100 && var.quota_gb <= 102400
    error_message = "quota_gb must be between 100 GB and 100 TB (102400 GB)."
  }
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "List of IP address ranges allowed to access the storage account (CIDR format)"
  type        = list(string)
  default     = []
}

variable "create_private_endpoint" {
  description = "Create a private endpoint for the storage account"
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs for the private endpoint"
  type        = list(string)
  default     = []
}

variable "create_dns_record" {
  description = "Create DNS A record for the storage account"
  type        = bool
  default     = false
}

variable "private_dns_zone_name" {
  description = "Name of the private DNS zone for DNS record creation"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
