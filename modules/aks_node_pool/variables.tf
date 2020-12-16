# REQUIRED variables (must be set by caller of the module)

variable "node_pool_name" {
  type = string
}

variable "aks_cluster_id" {
  type = string
}

variable "availability_zones" {
  type    = list(string)
  default = []
}

variable "vnet_subnet_id" {
  default = null
}

variable "machine_type" {
  type = string
}

variable "os_disk_size" {
  default = 100
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

variable "priority" {
  description = "The Priority for Virtual Machines within the Virtual Machine Scale Set that powers this Node Pool. Possible values are Regular and Spot. Defaults to Regular. Changing this forces a new resource to be created."
  type        = string
  default     = "Regular"
}

variable "node_count" {
  default = 1
}

variable "enable_auto_scaling" {
  default = false
}

variable "enable_node_public_ip" {
  description = "Should each node have a Public IP Address? Defaults to false"
  type        = bool
  default     = false
}

variable "eviction_policy" {
  description = "The Eviction Policy which should be used for Virtual Machines within the Virtual Machine Scale Set powering this Node Pool. Possible values are Deallocate and Delete. Changing this forces a new resource to be created. An Eviction Policy can only be configured when priority is set to Spot"
  type        = string
  default     = null
}

variable "max_pods" {
  description = "The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = 110
}

variable "mode" {
  description = "Should this Node Pool be used for System or User resources? Possible values are System and User. Defaults to User"
  type        = string
  default     = "User"
}

variable "max_nodes" {
  default = 1
}

variable "min_nodes" {
  default = 1
}

variable "node_taints" {
  type    = list
  default = []
}

variable "node_labels" {
  type    = map
  default = {}
}

variable "orchestrator_version" {
  description = "Version of Kubernetes used for the Agents. If not specified, the latest recommended version will be used at provisioning time (but won't auto-upgrade)"
  type        = string
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
}

variable "proximity_placement_group_id" {
  type    = string
  default = ""
}
