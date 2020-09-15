variable aks_cluster_name {}

variable aks_cluster_rg {}
variable aks_cluster_dns_prefix {}

variable aks_client_id {}

variable aks_client_secret {}

variable "aks_cluster_location" {
    description = "The Azure Region in which all resources in this example should be provisioned"
    default = "East US"
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
  default = "~/.ssh/id_rsa.pub"
}

# https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler
variable "aks_cluster_node_auto_scaling" {
    description = "To enable auto-scaler to add nodes to AKS cluster"
    default = false
}

variable kubernetes_version {
    description = "The AKS cluster K8s version"
    default = "1.16.13"
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
  default     = {project_name="viya"}
}
