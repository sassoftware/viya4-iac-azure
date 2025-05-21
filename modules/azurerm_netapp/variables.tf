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

variable "netapp_enable_cmk_encryption" {
  description = "Setting this variable to true enables CMK encryption on the netapp account.  Only relevant when storage_type=ha."
  type        = bool
  default     = false
}

variable "netapp_cmk_encryption_key_id" {
  description = "The ID of the key in keyvault to Encrypt ANF with (i.e. https://<keyvault-name>.vault.azure.net/keys/<key-name>).  Must exist before running terraform.  Only relevant when storage_type=ha.  Required if enable_anf_cmk_encryption is true."
  type        = string
  default     = null
}

variable "netapp_cmk_encryption_key_uai" {
  description = "The user assigned identity that will be used to access the key (i.e. /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<uai name>).  Must exist and have Key Vault Crypto Service Encryption User permission on the keyvault before running terraform.  Only relevant when storage_type=ha.  Required if enable_anf_cmk_encryption is true."
  type        = string
  default     = null
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
