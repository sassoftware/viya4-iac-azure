# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## Global
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

variable "subscription_id" {
  description = "The ID of the Subscription."
  type        = string
}

variable "tenant_id" {
  description = "The ID of the Tenant to which the subscription belongs"
  type        = string
}

variable "use_msi" {
  description = "Use Managed Identity for Authentication (Azure VMs only)"
  type        = bool
  default     = false
}

variable "msi_network_roles" {
    description = "Managed Identity permissions for VNet and Route Table"
    type = list(string)
    default = ["Network Contributor"]
}

variable "iac_tooling" {
  description = "Value used to identify the tooling used to generate this providers infrastructure."
  type        = string
  default     = "terraform"
}

variable "partner_id" {
  description = "A GUID/UUID that is registered with Microsoft to facilitate partner resource usage attribution"
  type        = string
  default     = "5d27f3ae-e49c-4dea-9aa3-b44e4750cd8c"
}

variable "prefix" {
  description = "A prefix used in the name for all cloud resources created by this script. The prefix string must start with lowercase letter and contain only lowercase alphanumeric characters and hyphen or dash(-), but can not start or end with '-'."
  type        = string

  validation {
    condition     = can(regex("^[a-z][-0-9a-z]*[0-9a-z]$", var.prefix)) && length(var.prefix) > 2 && length(var.prefix) < 21
    error_message = "ERROR: Value of 'prefix'\n * must start with lowercase letter and at most be 20 characters in length\n * can only contain lowercase letters, numbers, and hyphen or dash(-), but can't start or end with '-'."
  }
}

variable "location" {
  description = "The Azure Region to provision all resources in this script"
  type        = string
  default     = "eastus"
}

## Azure AD
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

  validation {
    condition     = contains(["KubernetesOfficial", "AKSLongTermSupport"], var.cluster_support_tier)
    error_message = "ERROR: Valid types are \"KubernetesOfficial\" and \"AKSLongTermSupport\"!"
  }
}

## Enable FIPS support
variable "fips_enabled" {
  description = "Enables the Federal Information Processing Standard for the nodes and VMs in this cluster. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "A custom ssh key to control access to the AKS cluster. Changing this forces a new resource to be created."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "default_public_access_cidrs" {
  description = "Default list of CIDRs to access created resources."
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster."
  type        = list(string)
  default     = null
}

variable "acr_public_access_cidrs" {
  description = "List of CIDRs to access Azure Container Registry."
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump or nfs VM."
  type        = list(string)
  default     = null
}

variable "postgres_public_access_cidrs" {
  description = "List of CIDRs to access PostgreSQL server."
  type        = list(string)
  default     = null
}

variable "default_nodepool_vm_type" {
  description = "The default virtual machine size for the Kubernetes agents"
  type        = string
  default     = "Standard_E8s_v5"
}

variable "kubernetes_version" {
  description = "The AKS cluster K8s version"
  type        = string
  default     = "1.30"
}

variable "default_nodepool_max_nodes" {
  description = "(Required, when default_nodepool_auto_scaling=true) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  type        = number
  default     = 5
}

variable "default_nodepool_min_nodes" {
  description = "(Required, when default_nodepool_auto_scaling=true) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  type        = number
  default     = 1
}

variable "default_nodepool_os_disk_size" {
  description = "The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
  type        = number
  default     = 128
}

variable "default_nodepool_max_pods" {
  description = "The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = 110
}

variable "default_nodepool_availability_zones" {
  description = "A list of Availability Zones across which the Node Pool should be spread. Changing this forces a new resource to be created."
  type        = list(string)
  default     = ["1"]
}

variable "aks_cluster_enable_host_encryption" {
  description = "Enables host encryption on all the nodes in the Node Pool."
  type        = bool
  default     = false
}

variable "aks_node_disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set which should be used for the Nodes and Volumes. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

# AKS advanced network config
variable "aks_network_plugin" {
  description = "Network plugin to use for networking. Currently supported values are azure and kubenet. Changing this forces a new resource to be created."
  type        = string
  default     = "kubenet"

  validation {
    condition     = contains(["kubenet", "azure"], var.aks_network_plugin)
    error_message = "Error: Currently the supported values are 'kubenet' and 'azure'."
  }
}

variable "aks_network_policy" {
  description = "Sets up network policy to be used with Azure CNI. Network policy allows control of the traffic flow between pods. Currently supported values are calico and azure. Changing this forces a new resource to be created."
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

variable "cluster_egress_type" {
  description = "The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer and userDefinedRouting. Defaults to loadBalancer."
  type        = string
  default     = null

  validation {
    condition     = var.cluster_egress_type != null ? contains(["loadBalancer", "userDefinedRouting"], var.cluster_egress_type) : true
    error_message = "ERROR: Supported values for `cluster_egress_type` are: loadBalancer, userDefinedRouting."
  }
}

variable "aks_uai_name" {
  description = "User assigned identity name"
  type        = string
  default     = null
}

variable "node_vm_admin" {
  description = "The username of the local administrator to be created on the Kubernetes cluster. OS Admin User for VMs of AKS Cluster nodes"
  type        = string
  default     = "azureuser"
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = {}
}

## PostgreSQL

# Defaults
variable "postgres_server_defaults" {
  description = ""
  type        = any
  default = {
    sku_name                     = "GP_Standard_D4s_v3"
    storage_mb                   = 131072
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false
    administrator_login          = "pgadmin"
    administrator_password       = "my$up3rS3cretPassw0rd"
    server_version               = "15"
    ssl_enforcement_enabled      = true
    connectivity_method          = "public"
    postgresql_configurations    = []
  }
}

# User inputs
variable "postgres_servers" {
  description = "Map of PostgreSQL server objects"
  type        = any
  default     = null

  # Checking for user provided "default" server
  validation {
    condition     = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? contains(keys(var.postgres_servers), "default") : false : true
    error_message = "ERROR: The provided map of PostgreSQL server objects does not contain the required 'default' key."
  }

  # Checking user provided login
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k, v in var.postgres_servers : contains(keys(v), "administrator_login") ? !contains(["azure_superuser", "azure_pg_admin", "admin", "administrator", "root", "guest", "public"], v.administrator_login) && !can(regex("^pg_", v.administrator_login)) : true
    ]) : false : true
    error_message = "ERROR: The admin login name can't be azure_superuser, azure_pg_admin, admin, administrator, root, guest, or public. It can't start with pg_."
  }

  # Checking user provided password
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k, v in var.postgres_servers : contains(keys(v), "administrator_password") ? alltrue([
        length(v.administrator_password) > 7,
        length(v.administrator_password) < 129,
        anytrue([
          (can(regex("[0-9]+", v.administrator_password)) && can(regex("[a-z]+", v.administrator_password)) && can(regex("[A-Z]+", v.administrator_password))),
          (can(regex("[!@#$%^&*(){}[]|<>~`,./_-+=]+", v.administrator_password)) && can(regex("[a-z]+", v.administrator_password)) && can(regex("[A-Z]+", v.administrator_password))),
          (can(regex("[!@#$%^&*(){}[]|<>~`,./_-+=]+", v.administrator_password)) && can(regex("[0-9]+", v.administrator_password)) && can(regex("[A-Z]+", v.administrator_password))),
          (can(regex("[!@#$%^&*(){}[]|<>~`,./_-+=]+", v.administrator_password)) && can(regex("[0-9]+", v.administrator_password)) && can(regex("[a-z]+", v.administrator_password)))
      ])]) : true
    ]) : false : true
    error_message = "ERROR: Password is not complex enough. It must contain between 8 and 128 characters. Your password must contain characters from three of the following categories:\n * English uppercase letters,\n * English lowercase letters,\n * numbers (0 through 9), and\n * non-alphanumeric characters (!, $, #, %, etc.)."
  }
}

variable "create_jump_vm" {
  description = "Creates bastion host VM"
  type        = bool
  default     = true
}

variable "create_jump_public_ip" {
  description = "Creates public IP for the bastion host VM"
  type        = bool
  default     = true
}

variable "enable_jump_public_static_ip" {
  description = "Enables `Static` allocation method for the public IP address of Jump Server. Setting false will enable `Dynamic` allocation method."
  type        = bool
  default     = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM"
  type        = string
  default     = "jumpuser"
}

variable "jump_vm_zone" {
  description = "The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created"
  type        = string
  default     = null
}

variable "jump_vm_machine_type" {
  description = "SKU which should be used for this Virtual Machine"
  type        = string
  default     = "Standard_B2s"
}

variable "jump_rwx_filestore_path" {
  description = "OS path used in cloud-init for NFS integration"
  type        = string
  default     = "/viya-share"
}

variable "enable_vm_host_encryption" {
  description = "Setting this variable enables all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host. This setting applies to both Jump and NFS VM. Defaults to false"
  type        = bool
  default     = false
}

variable "vm_disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk. This setting applies to both Jump and NFS VM."
  type        = string
  default     = null
}

variable "storage_type" {
  description = "Type of Storage. Valid Values: `standard`, `ha` and `none`. `standard` creates NFS server VM, `ha` creates Azure Netapp Files"
  type        = string
  default     = "standard"
  # NOTE: storage_type=none is for internal use only
  validation {
    condition     = contains(["standard", "ha", "none"], lower(var.storage_type))
    error_message = "ERROR: Supported values for `storage_type` are - standard, ha, none."
  }
}

variable "create_nfs_public_ip" {
  description = "Create public IP for the NFS VM"
  type        = bool
  default     = false
}

variable "enable_nfs_public_static_ip" {
  description = "Enables `Static` allocation method for the public IP address of NFS Server. Setting false will enable `Dynamic` allocation method."
  type        = bool
  default     = true
}

variable "nfs_vm_machine_type" {
  description = "SKU which should be used for this Virtual Machine"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM, when storage_type=standard"
  type        = string
  default     = "nfsuser"
}

variable "nfs_vm_zone" {
  description = "The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created"
  type        = string
  default     = null
}

variable "nfs_raid_disk_size" {
  description = "Size in Gb for each disk of the RAID5 cluster, when storage_type=standard"
  type        = number
  default     = 256
}

variable "nfs_raid_disk_type" {
  description = "The type of storage to use for the managed disk. Possible values are Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS."
  type        = string
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "UltraSSD_LRS"], var.nfs_raid_disk_type)
    error_message = "ERROR: nfs_raid_disk_type - Valid values include - Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS."
  }
}

variable "nfs_raid_disk_zone" {
  description = "Specifies the Availability Zone in which this Managed Disk should be located. Changing this property forces a new resource to be created."
  type        = string
  default     = null
}

## Azure Container Registry (ACR)
variable "create_container_registry" {
  description = "Create Azure Container Registry"
  type        = bool
  default     = false
}

variable "container_registry_sku" {
  description = "The SKU name of the container registry. Possible values are `Basic`, `Standard` and `Premium`."
  type        = string
  default     = "Standard"
}

variable "container_registry_admin_enabled" {
  description = "Specifies whether the admin user is enabled. Defaults to `false`."
  type        = bool
  default     = false
}

variable "container_registry_geo_replica_locs" {
  description = "A location where the container registry should be geo-replicated."
  type        = list(any)
  default     = null
}

# Azure NetApp Files
variable "netapp_service_level" {
  description = "When storage_type=ha, The target performance of the file system. Valid values include Premium, Standard, or Ultra"
  type        = string
  default     = "Premium"

  validation {
    condition     = var.netapp_service_level != null ? contains(["Premium", "Standard", "Ultra"], var.netapp_service_level) : null
    error_message = "ERROR: netapp_service_level - Valid values include - Premium, Standard, or Ultra."
  }
}

variable "netapp_size_in_tb" {
  description = "When storage_type=ha, Provisioned size of the pool in TB. Value must be between 4 and 500"
  type        = number
  default     = 4

  validation {
    condition     = var.netapp_size_in_tb != null ? var.netapp_size_in_tb >= 4 && var.netapp_size_in_tb <= 500 : null
    error_message = "ERROR: netapp_size_in_tb - value must be between 4 and 500."
  }
}

variable "netapp_protocols" {
  description = "The target volume protocol expressed as a list. Supported single value include CIFS, NFSv3, or NFSv4.1. If argument is not defined it will default to NFSv4.1. Changing this forces a new resource to be created and data will be lost."
  type        = list(string)
  default     = ["NFSv4.1"]
}

variable "netapp_volume_path" {
  description = "A unique file path for the volume. Used when creating mount targets. Changing this forces a new resource to be created"
  type        = string
  default     = "export"
}

variable "netapp_network_features" {
  description = "Indicates which network feature to use, accepted values are Basic or Standard, it defaults to Basic if not defined."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard"], var.netapp_network_features)
    error_message = "Error: Currently the supported values are 'Basic' and 'Standard'."
  }
}

variable "node_pools_availability_zone" {
  description = "Specifies a Availability Zone in which the Kubernetes Cluster Node Pool should be located."
  type        = string
  default     = "1"
}

variable "node_pools_availability_zones" {
  description = "Specifies a list of Availability Zones in which the Kubernetes Cluster Node Pool should be located. Changing this forces a new Kubernetes Cluster Node Pool to be created."
  type        = list(string)
  default     = null
}

variable "node_pools_proximity_placement" {
  description = "Enables Node Pool Proximity Placement Group"
  type        = bool
  default     = false
}

variable "node_pools" {
  description = "Node pool definitions"
  type = map(object({
    machine_type = string
    os_disk_size = number
    min_nodes    = string
    max_nodes    = string
    max_pods     = string
    node_taints  = list(string)
    node_labels  = map(string)
  }))

  default = {
    cas = {
      "machine_type" = "Standard_E16ds_v5"
      "os_disk_size" = 200
      "min_nodes"    = 0
      "max_nodes"    = 5
      "max_pods"     = 110
      "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "cas"
      }
    },
    compute = {
      "machine_type" = "Standard_D4ds_v5"
      "os_disk_size" = 200
      "min_nodes"    = 1
      "max_nodes"    = 5
      "max_pods"     = 110
      "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "compute"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
    },
    stateless = {
      "machine_type" = "Standard_D4s_v5"
      "os_disk_size" = 200
      "min_nodes"    = 0
      "max_nodes"    = 5
      "max_pods"     = 110
      "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateless"
      }
    },
    stateful = {
      "machine_type" = "Standard_D4s_v5"
      "os_disk_size" = 200
      "min_nodes"    = 0
      "max_nodes"    = 3
      "max_pods"     = 110
      "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateful"
      }
    }
  }
}

# Azure Monitor - Experimental
variable "create_aks_azure_monitor" {
  description = "Enable Azure Log Analytics agent on AKS cluster"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_sku" {
  description = "Specifies the Sku of the Log Analytics Workspace. Possible values are Free, PerNode, Premium, Standard, Standalone, Unlimited, and PerGB2018 (new Sku as of 2018-04-03)"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  description = "The workspace data retention in days. Possible values are either 7 (Free Tier only) or range between 30 and 730."
  type        = number
  default     = 30
}

variable "log_analytics_solution_name" {
  type        = string
  description = "The publisher of the solution. For example Microsoft. Changing this forces a new resource to be created"
  default     = "ContainerInsights"
}

variable "log_analytics_solution_publisher" {
  type        = string
  description = "The publisher of the solution. For example Microsoft. Changing this forces a new resource to be created"
  default     = "Microsoft"
}

variable "log_analytics_solution_product" {
  type        = string
  description = "The product name of the solution. For example OMSGallery/Containers. Changing this forces a new resource to be created."
  default     = "OMSGallery/ContainerInsights"
}

variable "log_analytics_solution_promotion_code" {
  type        = string
  description = "A promotion code to be used with the solution"
  default     = ""
}

## Azure Monitor Diagonostic setting - Experimental
variable "resource_log_category" {
  description = "List of all resource logs category types supported in Azure Monitor. See https://learn.microsoft.com/en-us/azure/aks/monitor-aks-reference#resource-logs."
  type        = list(string)
  default     = ["kube-controller-manager", "kube-apiserver", "kube-scheduler"]

  validation {
    condition     = length(var.resource_log_category) > 0
    error_message = "Please specify at least one resource log category. See the list of all resource logs category types supported in Azure Monitor here: https://learn.microsoft.com/en-us/azure/aks/monitor-aks-reference#resource-logs."
  }
}

variable "metric_category" {
  description = "List of all metric category types supported in Azure Monitor. See https://learn.microsoft.com/en-us/azure/aks/monitor-aks-reference#metrics."
  type        = list(string)
  default     = ["AllMetrics"]

  validation {
    condition     = length(var.metric_category) > 0
    error_message = "Please specify at least one metric category. See the list of all platform metrics supported in Azure Monitor here: https://learn.microsoft.com/en-us/azure/aks/monitor-aks-reference#metrics."
  }
}

# BYO
variable "resource_group_name" {
  description = "Name of pre-exising resource group. Leave blank to have one created"
  type        = string
  default     = null
}

variable "vnet_resource_group_name" {
  description = "Name of a pre-exising resource group containing the BYO vnet resource. Leave blank if you are not using a BYO vnet or if the BYO vnet is co-located with the SAS Viya4 AKS cluster."
  type        = string
  default     = null
}

variable "vnet_name" {
  description = "Name of pre-exising vnet. Leave blank to have one created"
  type        = string
  default     = null
}

variable "vnet_address_space" {
  description = "Address space for created vnet"
  type        = string
  default     = "192.168.0.0/16"
}

variable "nsg_name" {
  description = "Name of pre-exising NSG. Leave blank to have one created"
  type        = string
  default     = null
}

variable "egress_public_ip_name" {
  type        = string
  default     = null
  description = "DEPRECATED: Name of pre-existing Public IP for the Network egress."
}

variable "subnet_names" {
  description = "Map subnet usage roles to existing subnet names"
  type        = map(string)
  default     = {}
  # Example:
  # subnet_names = {
  #   'aks': 'my_aks_subnet',
  #   'misc': 'my_misc_subnet',
  #   'netapp': 'my_netapp_subnet'
  # }
}

variable "subnets" {
  description = "Subnets to be created and their settings"
  type = map(object({
    prefixes                                      = list(string)
    service_endpoints                             = list(string)
    private_endpoint_network_policies             = string
    private_link_service_network_policies_enabled = bool
    service_delegations = map(object({
      name    = string
      actions = list(string)
    }))
  }))
  default = {
    aks = {
      "prefixes" : ["192.168.0.0/23"],
      "service_endpoints" : ["Microsoft.Sql"],
      "private_endpoint_network_policies" : "Enabled",
      "private_link_service_network_policies_enabled" : false,
      "service_delegations" : {},
    }
    misc = {
      "prefixes" : ["192.168.2.0/24"],
      "service_endpoints" : ["Microsoft.Sql"],
      "private_endpoint_network_policies" : "Enabled",
      "private_link_service_network_policies_enabled" : false,
      "service_delegations" : {},
    }
    netapp = {
      "prefixes" : ["192.168.3.0/24"],
      "service_endpoints" : [],
      "private_endpoint_network_policies" : "Disabled",
      "private_link_service_network_policies_enabled" : false,
      "service_delegations" : {
        netapp = {
          "name" : "Microsoft.Netapp/volumes"
          "actions" : ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
  }
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider/service account based kube config file"
  type        = bool
  default     = true
}

variable "cluster_node_pool_mode" {
  description = "Flag for predefined cluster node configurations - Values : default, minimal"
  type        = string
  default     = "default"
}

variable "cluster_api_mode" {
  description = "Use Public or Private IP address for the cluster API endpoint"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], lower(var.cluster_api_mode))
    error_message = "ERROR: Supported values for `cluster_api_mode` are - public, private."
  }
}

variable "aks_identity" {
  description = "Use Service Principal or create a UserAssignedIdentity as AKS Identity."
  type        = string
  default     = "uai"
  validation {
    condition     = contains(["sp", "uai"], var.aks_identity)
    error_message = "ERROR: Supported values for `aks_identity` are: uai, sp."
  }
}

variable "aks_cluster_private_dns_zone_id" {
  description = "Specify private DNS zone resource ID for AKS private cluster to use."
  type        = string
  default     = ""
}
