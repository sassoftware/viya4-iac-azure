# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "node_pool_name" {
  description = "The name of the Node Pool which should be created within the Kubernetes Cluster. Changing this forces a new resource to be created."
  type        = string
}

variable "aks_cluster_id" {
  description = "The ID of the Kubernetes Cluster where this Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
}

variable "zones" {
  description = "Specifies a list of Availability Zones in which this Kubernetes Cluster Node Pool should be located. Changing this forces a new Kubernetes Cluster Node Pool to be created."
  type        = list(string)
  default     = []
}

variable "vnet_subnet_id" {
  description = "The ID of the Subnet where this Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "The SKU which should be used for the Virtual Machines used in this Node Pool. Changing this forces a new resource to be created."
  type        = string
}

variable "os_disk_size" {
  description = "The Agent Operating System disk size in GB. Changing this forces a new resource to be created."
  type        = number
  default     = 100
}

# TODO: enable after azurerm v2.37.0
# variable "os_disk_type" {
#   description = "The type of disk which should be used for the Operating System. Possible values are Ephemeral and Managed. Defaults to Managed. Changing this forces a new resource to be created"
#   type = string
#   default = "Managed"
# }

variable "os_type" {
  description = "The Operating System which should be used for this Node Pool. Changing this forces a new resource to be created. Possible values are Linux and Windows. Defaults to Linux"
  type        = string
  default     = "Linux"
}

variable "node_count" {
  description = "The number of nodes which should exist within this Node Pool."
  type        = number
  default     = 1
}

variable "enable_auto_scaling" {
  description = "Whether to enable auto-scaler."
  type        = bool
  default     = false
}

variable "max_pods" {
  description = "The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = 110
}

variable "max_nodes" {
  description = "The maximum number of nodes which should exist within this Node Pool."
  type        = number
  default     = 1
}

variable "min_nodes" {
  description = "The minimum number of nodes which should exist within this Node Pool."
  type        = number
  default     = 1
}

variable "node_taints" {
  description = "A list of the taints added to new nodes during node pool create and scale. Changing this forces a new resource to be created."
  type    = list(any)
  default = []
}

variable "node_labels" {
  description = "A map of Kubernetes labels which should be applied to nodes in this Node Pool."
  type        = map(any)
  default     = {}
}

variable "orchestrator_version" {
  description = "Version of Kubernetes used for the Agents. If not specified, the latest recommended version will be used at provisioning time (but won't auto-upgrade)"
  type        = string
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map(any)
}

variable "proximity_placement_group_id" {
  description = "The ID of the Proximity Placement Group where the Virtual Machine Scale Set that powers this Node Pool will be placed. Changing this forces a new resource to be created."
  type        = string
  default     = ""
}

# For future - https://docs.microsoft.com/en-us/azure/aks/spot-node-pool
#
# variable "priority" {
#   description = "The Priority for Virtual Machines within the Virtual Machine Scale Set that powers this Node Pool. Possible values are Regular and Spot. Defaults to Regular. Changing this forces a new resource to be created."
#   type        = string
#   default     = "Regular"
# }

# variable "eviction_policy" {
#   description = "The Eviction Policy which should be used for Virtual Machines within the Virtual Machine Scale Set powering this Node Pool. Possible values are Deallocate and Delete. Changing this forces a new resource to be created. An Eviction Policy can only be configured when priority is set to Spot"
#   type        = string
#   default     = null
# }

# variable "spot_max_price" {
#   description = "The maximum price you're willing to pay in USD per Virtual Machine. Valid values are -1 (the current on-demand price for a Virtual Machine) or a positive value with up to five decimal places. Changing this forces a new resource to be created."
#   type        = number
#   default     = -1
# }
