# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "A prefix used in the name for all the Azure resources created by this script."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the PostgreSQL Server. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "message_broker_sku" {
  description = "Defines which tier to use. Options are Basic, Standard or Premium. SAS Viya Platform recommends using 'Premium'."
  type        = string
  default     = "Premium"
}

variable "message_broker_name" {
  description = "Specifies the name of the message broker, also specified for the ServiceBus Namespace Authorization Rule resource. Changing this forces a new resource to be created."
  type        = string
  default     = "Arke"
}

variable "message_broker_capacity" {
  description = "Specifies the capacity. When sku is Premium, capacity can be 1, 2, 4, 8 or 16. When sku is Basic or Standard, capacity can be 0 only."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
}
