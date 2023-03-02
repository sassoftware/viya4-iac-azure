variable "aks_cluster_name" {
  description = "The name for the AKS resources created in the specified Azure Resource Group"
  type        = string
}

variable "aks_cluster_rg" {
  description = "The resource group name to be imported"
  type        = string
}

variable "aks_cluster_rg_id" {
  description = "The `azurerm_kubernetes_cluster`'s id."
  type        = string
}

variable "aks_cluster_dns_prefix" {
  description = "DNS prefix specified when creating the managed cluster."
  type        = string
}

variable "aks_cluster_location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
  type        = string
  default     = "eastus"
}

variable "aks_cluster_sku_tier" {
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid (which includes the Uptime SLA). Defaults to Free"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Paid"], var.aks_cluster_sku_tier)
    error_message = "ERROR: Valid types are \"Free\" and \"Paid\"!"
  }
}

variable "aks_private_cluster" {
  description = "The cluster API endpoint uses Private IP address?"
  type        = bool
  default     = false
}

variable "aks_cluster_node_count" {
  description = "(Required, when default_nodepool_auto_scaling=true) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  type        = number
  default     = 4
}

variable "aks_availability_zones" {
  description = "A list of Availability Zones across which the Node Pool should be spread. Changing this forces a new resource to be created."
  type        = list(string)
  default     = ["1"]
}

# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes
variable "aks_cluster_node_vm_size" {
  description = "The default virtual machine size for the Kubernetes agents"
  type        = string
  default     = "Standard_D4_v2"
}

variable "aks_cluster_node_admin" {
  description = "The operating system Admin User for VMs of AKS cluster nodes"
  type        = string
  default     = "ubuntu"
}

variable "aks_cluster_ssh_public_key" {
  description = "A custom ssh key to control access to the AKS cluster. Changing this forces a new resource to be created."
  type        = string
  default     = ""
}

# https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler
variable "aks_cluster_node_auto_scaling" {
  description = "To enable auto-scaler to add nodes to AKS cluster"
  type        = bool
  default     = false
}

variable "aks_cluster_min_nodes" {
  description = "(Required, when aks_cluster_node_auto_scaling=true) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  type        = number
  default     = 1
}

variable "aks_cluster_max_nodes" {
  description = "(Required, when aks_cluster_node_auto_scaling=true) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  type        = number
  default     = 3
}

variable "aks_cluster_os_disk_size" {
  description = "(Optional) The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
  type        = number
  default     = 128
}

variable "aks_cluster_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = 110
}

variable "kubernetes_version" {
  description = "The AKS cluster K8s version"
  type        = string
  default     = "1.24"
}

variable "aks_cluster_endpoint_public_access_cidrs" {
  description = "Kubernetes cluster access IP ranges"
  type        = list(any)
}

variable "aks_vnet_subnet_id" {
  description = "(Optional) The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
  default     = null
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
  type        = string
  default     = "172.17.0.1/16"
}

variable "aks_pod_cidr" {
  description = "The CIDR to use for pod IP addresses. This field can only be set when network_plugin is set to kubenet. Changing this forces a new resource to be created."
  type        = string
  default     = "10.244.0.0/16"
}

variable "aks_service_cidr" {
  description = "The Network Range used by the Kubernetes service. Changing this forces a new resource to be created."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_cluster_tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map(any)
}

variable "aks_oms_enabled" {
  description = "Enable Azure Log Analytics agent"
  type        = bool
}

variable "aks_log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace which the OMS Agent should send data to. Must be present if aks_oms_enabled is true"
  type        = string
}

variable "aks_uai_id" {
  description = "User assigned identity ID"
  type        = string
  default     = null
}

variable "client_id" {
  description = "(Required) The Client ID for the Service Principal"
  type        = string
  default     = ""
}

variable "client_secret" {
  description = "(Required) The Client Secret for the Service Principal."
  type        = string
  default     = ""
}

variable "cluster_egress_type" {
  description = "The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer and userDefinedRouting. Defaults to loadBalancer."
  type        = string
  default     = "loadBalancer"
}
