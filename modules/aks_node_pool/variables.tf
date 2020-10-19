# REQUIRED variables (must be set by caller of the module)

variable "node_pool_name" {
  type = string
}

variable "aks_cluster_id" {
  type = string
}

variable "availability_zones" {
  type = list
  default = ["1", "2", "3"]
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

variable "node_count" {
  default = 1
}

variable "enable_auto_scaling" {
  default = false
}

variable "max_nodes" {
  default = 1
}

variable "min_nodes" {
  default = 1
}

variable "node_taints" {
  type = list
  default = []
}

variable "node_labels" {
  type = map
  default = {}
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
}
