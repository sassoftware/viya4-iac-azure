# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "aks_cluster_name" {
  description = "The name for the AKS resources created in the specified Azure Resource Group"
  type        = string
}

variable "aks_cluster_rg" {
  description = "The resource group name to be imported"
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

variable "rbac_aad_enabled" {
  type        = bool
  description = "Enables Azure Active Directory integration with Kubernetes RBAC."
  default     = false
}

variable "rbac_aad_admin_group_object_ids" {
  type        = list(string)
  description = "A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster."
  default     = null
}

variable "rbac_aad_tenant_id" {
  type        = string
  description = "(Optional) The Tenant ID used for Azure Active Directory Application. If this isn't specified the Tenant ID of the current Subscription is used."
  default     = null
}

variable "aks_cluster_sku_tier" {
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free, Standard (which includes the Uptime SLA) and Premium. Defaults to Free"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.aks_cluster_sku_tier)
    error_message = "ERROR: Valid types are \"Free\", \"Standard\" and \"Premium\"!"
  }
}

variable "cluster_support_tier" {
  description = "Specifies the support plan which should be used for this Kubernetes Cluster. Possible values are 'KubernetesOfficial' and 'AKSLongTermSupport'. Defaults to 'KubernetesOfficial'."
  type        = string
  default     = "KubernetesOfficial"
}

variable "fips_enabled" {
  description = "Should the nodes in this Node Pool have Federal Information Processing Standard enabled? Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "aks_private_cluster" {
  description = "Enables cluster API endpoint to use Private IP address"
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
  description = "The default virtual machine size for the AKS cluster nodes"
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
  description = "The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
  type        = number
  default     = 128
}

variable "aks_cluster_max_pods" {
  description = "The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = 110
}

variable "aks_cluster_enable_host_encryption" {
  description = "Enables host encryption on all the nodes in the Default Node Pool"
  type        = bool
  default     = false
}

variable "aks_node_disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set which should be used for the Nodes and Volumes. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "aks_azure_policy_enabled" {
  description = "Enables the Azure Policy Add-On for Azure Kubernetes Service."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "The AKS cluster K8s version"
  type        = string
  default     = "1.30"
}

variable "aks_cluster_endpoint_public_access_cidrs" {
  description = "Azure Kubernetes cluster access IP ranges"
  type        = list(any)
}

variable "aks_vnet_subnet_id" {
  description = "The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created."
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
  default     = null
}

variable "aks_network_plugin_mode" {
  description = "Specifies the network plugin mode used for building the Kubernetes network. Possible value is `overlay`. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "aks_dns_service_ip" {
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns). Changing this forces a new resource to be created."
  type        = string
  default     = "10.0.0.10"
  validation {
    condition     = var.aks_dns_service_ip != null ? can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.aks_dns_service_ip)) : false
    error_message = "ERROR: aks_dns_service_ip - value must not be null and must be a valid IP address."
  }
}

variable "aks_pod_cidr" {
  description = "The CIDR to use for pod IP addresses. This field can only be set when network_plugin is set to kubenet. Changing this forces a new resource to be created."
  type        = string
  default     = "10.244.0.0/16"
  validation {
    condition     = var.aks_pod_cidr != "" ? can(cidrnetmask(var.aks_pod_cidr)) : true
    error_message = "ERROR: aks_pod_cidr - value must either be null or must be a valid CIDR."
  }

}

variable "aks_service_cidr" {
  description = "The Network Range used by the Kubernetes service. Changing this forces a new resource to be created."
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = var.aks_service_cidr != null ? can(cidrnetmask(var.aks_service_cidr)) : false
    error_message = "ERROR: aks_service_cidr - value must not be null and must be a valid CIDR."
  }

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
  description = "The Client ID for the Service Principal"
  type        = string
  default     = ""
}

variable "client_secret" {
  description = "The Client Secret for the Service Principal."
  type        = string
  default     = ""
}

variable "cluster_egress_type" {
  description = "The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer and userDefinedRouting. Defaults to loadBalancer."
  type        = string
  default     = "loadBalancer"
}

variable "aks_cluster_private_dns_zone_id" {
  type    = string
  default = ""
}

variable "aks_cluster_run_command_enabled" {
  description = "Enable or disable the AKS cluster Run Command feature."
  type        = bool
  default     = false
}
