variable aks_cluster_name {}

variable aks_cluster_rg {}
variable aks_cluster_dns_prefix {}

variable aks_client_id {}

variable aks_client_secret {}

variable "aks_cluster_location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
  default     = "East US"
}

variable "aks_cluster_node_count" {
  default = 4
}

variable "aks_availability_zones" {}

# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
variable "aks_cluster_node_vm_size" {
  default = "Standard_D4_v2"
}

variable "aks_cluster_node_admin" {
  default = "ubuntu"
}

variable "aks_cluster_ssh_public_key" {
  default = ""
}

# https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler
variable "aks_cluster_node_auto_scaling" {
  description = "To enable auto-scaler to add nodes to AKS cluster"
  default     = false
}

variable "aks_cluster_min_nodes" {
  description = "(Required, when aks_cluster_node_auto_scaling=true) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  default     = 1
}
variable "aks_cluster_max_nodes" {
  description = "(Required, when aks_cluster_node_auto_scaling=true) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  default     = 3
}
variable "aks_cluster_os_disk_size" {
  description = "(Optional) The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
  default     = 128
}
variable "aks_cluster_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  default     = 110
}

variable kubernetes_version {
  description = "The AKS cluster K8s version"
  default     = "1.18.8"
}
variable "aks_cluster_endpoint_public_access_cidrs" {
  description = "Kubernetes cluster access IP ranges"
  type        = list
}

variable "aks_vnet_subnet_id" {
  default = null
}

variable "aks_network_plugin" {
  default = "kubenet"
}

variable "aks_cluster_tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
}

variable "aks_oms_enabled" {
  description = "Enable Azure Log Analytics agent"
  type = bool
}

variable "aks_log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace which the OMS Agent should send data to. Must be present if aks_oms_enabled is true"
}
