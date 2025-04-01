# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
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

variable "fips_enabled" {
  description = "Should the nodes in this Node Pool have Federal Information Processing Standard enabled? Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "host_encryption_enabled" {
  description = "Enables host encryption on all the nodes in the Node Pool. Changing this forces a new resource to be created."
  type        = bool
  default     = false
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

variable "auto_scaling_enabled" {
  description = "Whether to enable auto-scaler."
  type        = bool
  default     = false
}

variable "node_public_ip_enabled" {
  description = "Should nodes in this Node Pool have a Public IP Address"
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
  type        = list(any)
  default     = []
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

variable "linux_os_config"{
  description = "Specifications of linux os config. Changing this forces a new resource to be created."
  type = object({
      sysctl_config = optional(object({
        vm_max_map_count = optional(number)
        }))
      })
  default = {}
}