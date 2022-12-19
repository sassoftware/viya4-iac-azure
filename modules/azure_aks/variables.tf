variable aks_cluster_name {}

variable aks_cluster_rg {}
variable aks_cluster_rg_id {}
variable aks_cluster_dns_prefix {}

variable "aks_cluster_location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
  default     = "eastus"
}

variable aks_cluster_sku_tier {
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid (which includes the Uptime SLA). Defaults to Free"
  default     = "Free"

  validation {
    condition     = contains(["Free", "Paid"],  var.aks_cluster_sku_tier)
    error_message = "ERROR: Valid types are \"Free\" and \"Paid\"!"
  }
}

variable "aks_private_cluster" {
  default = false
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
  default     = "1.23.8"
}
variable "aks_cluster_endpoint_public_access_cidrs" {
  description = "Kubernetes cluster access IP ranges"
  type        = list
}

variable "aks_vnet_subnet_id" {
  default = null
}

variable "aks_network_plugin" {
  description = "Network plugin to use for networking. Currently supported values are azure and kubenet. Changing this forces a new resource to be created."
  type        = string
  default     = "kubenet"
}

variable "aks_network_policy" {
  description = "Sets up network policy to be used with Azure CNI. Network policy allows us to control the traffic flow between pods. Currently supported values are calico and azure. Changing this forces a new resource to be created."
  type        = string
  default     = "azure"
}

variable "aks_dns_service_ip" {
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns). Changing this forces a new resource to be created."
  type        = string
  default     = "10.0.0.10"
}

variable "aks_docker_bridge_cidr" {
  description = "IP address (in CIDR notation) used as the Docker bridge IP address on nodes. Changing this forces a new resource to be created."
  default     = "172.17.0.1/16"
}

variable "aks_pod_cidr" {
  description = "The CIDR to use for pod IP addresses. This field can only be set when network_plugin is set to kubenet. Changing this forces a new resource to be created."
  default     = "10.244.0.0/16"
}

variable "aks_service_cidr" {
  description = "The Network Range used by the Kubernetes service. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "aks_cluster_tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
}

variable "aks_oms_enabled" {
  description = "Enable Azure Log Analytics agent"
  type        = bool
}

variable "aks_log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace which the OMS Agent should send data to. Must be present if aks_oms_enabled is true"
}

variable "aks_uai_id"{
  description = "User assigned identity ID"
  default = null
} 

variable client_id {
  default = ""
}
variable client_secret {
  default = ""
}

variable "cluster_egress_type" {
  default = "loadBalancer"
}
