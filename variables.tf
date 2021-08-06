variable client_id {
  default = ""
}
variable client_secret {
  default = ""
}

variable subscription_id {}
variable tenant_id {}

variable use_msi {
  description = "Use Managed Identity for Authentication (Azure VMs only)"
  type        = bool
  default     = false
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
  default     = "East US"
}

variable "ssh_public_key" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources"
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster"
  type        = list(string)
  default     = null
}

variable "acr_public_access_cidrs" {
  description = "List of CIDRs to access Azure Container Registry"
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump or nfs VM"
  type        = list(string)
  default     = null
}

variable "postgres_public_access_cidrs" {
  description = "LList of CIDRs to access PostgreSQL server"
  type        = list(string)
  default     = null
}

variable "default_nodepool_vm_type" {
  default = "Standard_D8s_v4"
}
variable "kubernetes_version" {
  description = "The AKS cluster K8s version"
  default     = "1.19.11"
}

variable "default_nodepool_max_nodes" {
  description = "(Required, when default_nodepool_auto_scaling=true) The maximum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  default     = 5
}
variable "default_nodepool_min_nodes" {
  description = "(Required, when default_nodepool_auto_scaling=true) The minimum number of nodes which should exist in this Node Pool. If specified this must be between 1 and 100."
  default     = 1
}
variable "default_nodepool_os_disk_size" {
  description = "(Optional) The size of the OS Disk which should be used for each agent in the Node Pool. Changing this forces a new resource to be created."
  default     = 128
}
variable "default_nodepool_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  default     = 110
}

variable "default_nodepool_availability_zones" {
  type    = list
  default = ["1"]
}

# AKS advanced network config
variable "aks_network_plugin" {
  description = "Network plugin to use for networking. Currently supported values are azure and kubenet. Changing this forces a new resource to be created."
  type        = string
  default     = "kubenet"
  #TODO: add validation when value is 'azure'
}

variable "aks_network_policy" {
  description = "Sets up network policy to be used with Azure CNI. Network policy allows us to control the traffic flow between pods. Currently supported values are calico and azure. Changing this forces a new resource to be created."
  type        = string
  default     = "azure"
  #TODO: add validation
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

variable "aks_outbound_type" {
  description = "The outbound (egress) routing method which should be used for this Kubernetes Cluster. Possible values are loadBalancer and userDefinedRouting. Defaults to loadBalancer."
  default     = "loadBalancer"
}

variable "aks_pod_cidr" {
  description = "The CIDR to use for pod IP addresses. This field can only be set when network_plugin is set to kubenet. Changing this forces a new resource to be created."
  default     = "10.244.0.0/16"
}

variable "aks_service_cidr" {
  description = "The Network Range used by the Kubernetes service. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "aks_uai_name"{
  description = "User assigned identity name"
  default = null
} 

variable "node_vm_admin" {
  description = "OS Admin User for VMs of AKS Cluster nodes"
  default     = "azureuser"
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
  default     = {}
}

## PostgresSQL inputs
variable "create_postgres" {
  description = "Create an Azure PostgresSQL database server instance"
  type        = bool
  default     = false
}

variable "postgres_sku_name" {
  description = "SKU Name for the PostgreSQL Server. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen4_1, GP_Gen5_4)."
  default     = "GP_Gen5_32"
}
variable "postgres_storage_mb" {
  description = "Max storage allowed for the PostgreSQL server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs."
  default     = 51200
}

variable "postgres_backup_retention_days" {
  description = "Backup retention days for the PostgreSQL server, supported values are between 7 and 35 days."
  default     = 7
}

variable "postgres_geo_redundant_backup_enabled" {
  description = "Enable Geo-redundant backup for PostgreSQL server. Not supported for the basic tier."
  default     = false
}

# https://docs.microsoft.com/en-us/azure/postgresql/quickstart-create-server-database-portal
# The admin login name can't be azure_superuser, azure_pg_admin, admin, administrator, root, guest, or public. It can't start with pg_.
variable "postgres_administrator_login" {
  description = "The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created."
  default     = "pgadmin"

  validation {
    condition     = ! contains(["azure_superuser", "azure_pg_admin", "admin", "administrator", "root", "guest", "public"], var.postgres_administrator_login) && ! can(regex("^pg_", var.postgres_administrator_login))
    error_message = "ERROR: The admin login name can't be azure_superuser, azure_pg_admin, admin, administrator, root, guest, or public. It can't start with pg_."
  }
}
# A new password for the server admin account. It must contain between 8 and 128 characters. Your password must contain characters from three of the following categories: 
# English uppercase letters, English lowercase letters, numbers (0 through 9), and non-alphanumeric characters (!, $, #, %, etc.).
variable "postgres_administrator_password" {
  description = "The Password associated with the postgres_administrator_login for the PostgreSQL Server."
  default     = null

  validation {
    condition     = var.postgres_administrator_password != null ? length(var.postgres_administrator_password) > 7 && length(var.postgres_administrator_password) < 127 : true
    error_message = "ERROR: 'postgres_administrator_password' must contain between 8 and 128 characters."
  }
  validation {
    condition     = var.postgres_administrator_password != null ? (can(regex("[0-9]+", var.postgres_administrator_password)) && can(regex("[a-z]+", var.postgres_administrator_password)) && can(regex("[A-Z]+", var.postgres_administrator_password))) || (can(regex("[!@#$%^&*(){}[]|<>~`,./_-+=]+", var.postgres_administrator_password)) && can(regex("[a-z]+", var.postgres_administrator_password)) && can(regex("[A-Z]+", var.postgres_administrator_password))) || (can(regex("[!@#$%^&*(){}[]|<>~`,./_-+=]+", var.postgres_administrator_password)) && can(regex("[0-9]+", var.postgres_administrator_password)) && can(regex("[A-Z]+", var.postgres_administrator_password))) || (can(regex("[!@#$%^&*(){}[]|<>~`,./_-+=]+", var.postgres_administrator_password)) && can(regex("[0-9]+", var.postgres_administrator_password)) && can(regex("[a-z]+", var.postgres_administrator_password))) : true
    error_message = "ERROR: Password is not complex enough. It must contain between 8 and 128 characters. Your password must contain characters from three of the following categories:\n * English uppercase letters,\n * English lowercase letters,\n * numbers (0 through 9), and\n * non-alphanumeric characters (!, $, #, %, etc.)."
  }
}

variable "postgres_server_version" {
  description = "Version of PostgreSQL to use. Valid values are 9.5, 9.6, and 10.0. Changing this forces a new resource to be created."
  default     = "11"
}

variable "postgres_ssl_enforcement_enabled" {
  description = "Enforce SSL on connections to PostgreSQL server."
  default     = true
}

variable "postgres_db_names" {
  description = "The list of names of PostgreSQL database to create. Needs to be a valid PostgreSQL identifier. Changing this forces a new resource to be created."
  default     = []
}

variable "postgres_db_charset" {
  description = "Charset for the PostgreSQL Database. Needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created."
  default     = "UTF8"
}

variable "postgres_db_collation" {
  description = "Collation for the PostgreSQL Database. Needs to be a valid PostgreSQL Collation. Note that Microsoft uses different notation - en-US instead of en_US. Changing this forces a new resource to be created."
  default     = "English_United States.1252"
}

variable "postgres_configurations" {
  description = "A map with PostgreSQL configurations to enable."
  type        = map
  default     = {}
}

variable "create_jump_vm" {
  description = "Create bastion host VM"
  default     = true
}

variable "create_jump_public_ip" {
  default = null
  type = bool
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM"
  default     = "jumpuser"
}

variable "jump_vm_zone" {
  description = "The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created"
  default     = null
}

variable "jump_vm_machine_type" {
  default = "Standard_B2s"
  description = "SKU which should be used for this Virtual Machine"
}

variable "jump_rwx_filestore_path" {
  description = "OS path used in cloud-init for NFS integration"
  default     = "/viya-share"
}

variable "storage_type" {
  type    = string
  default = "standard"

  validation {
    condition     = contains(["standard", "ha"], lower(var.storage_type))
    error_message = "ERROR: Supported value for `storage_type` are - standard, ha."
  }
}

variable "create_nfs_public_ip" {
  default = null
  type = bool
}

variable "nfs_vm_machine_type" {
  default     = "Standard_D8s_v4" # "Standard_E8s_v3" "Standard_D8s_v4"
  description = "SKU which should be used for this Virtual Machine"
}

variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM, when storage_type=standard"
  default     = "nfsuser"
}

variable "nfs_vm_zone" {
  description = "The Zone in which this Virtual Machine should be created. Changing this forces a new resource to be created"
  default     = null
}

variable "nfs_raid_disk_size" {
  description = "Size in Gb for each disk of the RAID5 cluster, when storage_type=standard"
  default     = 128
}

variable nfs_raid_disk_type {
  default     = "Standard_LRS"
  description = "The type of storage to use for the managed disk. Possible values are Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS."

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "UltraSSD_LRS"], var.nfs_raid_disk_type)
    error_message = "ERROR: nfs_raid_disk_type - Valid values include - Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS."
  }
}

variable nfs_raid_disk_zones {
  description = "A collection containing the availability zones to allocate the Managed Disk in."
  default     = []
}

# Azure Container Registry (ACR)
variable "create_container_registry" {
  type        = bool
  description = "Boolean flag to create container registry"
  default     = false
}
variable "container_registry_sku" {
  default = "Standard"
}
variable "container_registry_admin_enabled" {
  default = false
}
variable "container_registry_geo_replica_locs" {
  type    = list
  default = null
}

# Azure NetApp Files
variable netapp_service_level {
  description = "When storage_type=ha, The target performance of the file system. Valid values include Premium, Standard, or Ultra"
  default     = "Premium"

  validation {
    condition     = var.netapp_service_level != null ? contains(["Premium", "Standard", "Ultra"], var.netapp_service_level) : null
    error_message = "ERROR: netapp_service_level - Valid values include - Premium, Standard, or Ultra."
  }
}
variable netapp_size_in_tb {
  description = "When storage_type=ha, Provisioned size of the pool in TB. Value must be between 4 and 500"
  default     = 4

  validation {
    condition     = var.netapp_size_in_tb != null ? var.netapp_size_in_tb >= 4 && var.netapp_size_in_tb <= 500 : null
    error_message = "ERROR: netapp_size_in_tb - value must be between 4 and 500."
  }
}

variable netapp_protocols {
  description = "The target volume protocol expressed as a list. Supported single value include CIFS, NFSv3, or NFSv4.1. If argument is not defined it will default to NFSv3. Changing this forces a new resource to be created and data will be lost."
  default     = ["NFSv3"]
}
variable netapp_volume_path {
  description = "A unique file path for the volume. Used when creating mount targets. Changing this forces a new resource to be created"
  default     = "export"
}

variable node_pools_availability_zone {
  type    = string
  default = "1"
}

variable node_pools_proximity_placement {
  type    = bool
  default = false
}

variable node_pools {
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
      "machine_type" = "Standard_E16s_v3"
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
      "machine_type" = "Standard_E16s_v3"
      "os_disk_size" = 200
      "min_nodes"    = 0
      "max_nodes"    = 5
      "max_pods"     = 110
      "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "compute"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
    },
    connect = {
      "machine_type" = "Standard_E16s_v3"
      "os_disk_size" = 200
      "min_nodes"    = 0
      "max_nodes"    = 5
      "max_pods"     = 110
      "node_taints"  = ["workload.sas.com/class=connect:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "connect"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
    },
    stateless = {
      "machine_type" = "Standard_D16s_v3"
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
      "machine_type" = "Standard_D8s_v3"
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

# Azure Monitor
variable "create_aks_azure_monitor" {
  type        = bool
  description = "Enable Azure Log Analytics agent on AKS cluster"
  default     = "false"
}

variable "enable_log_analytics_workspace" {
  type        = bool
  description = "Enable Azure Log Analytics Solution"
  default     = true
}

variable "log_analytics_workspace_sku" {
  description = "Specifies the Sku of the Log Analytics Workspace. Possible values are Free, PerNode, Premium, Standard, Standalone, Unlimited, and PerGB2018 (new Sku as of 2018-04-03)"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  description = "(Optional) The workspace data retention in days. Possible values are either 7 (Free Tier only) or range between 30 and 730."
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
  description = " The publisher of the solution. For example Microsoft. Changing this forces a new resource to be created"
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

# BYO
variable "resource_group_name" {
  type    = string
  default = null
  description = "Name of pre-exising resource group. Leave blank to have one created"
}

variable "vnet_name" {
  type    = string
  default = null
  description = "Name of pre-exising vnet. Leave blank to have one created"
}

variable "vnet_address_space" {
  type        = string
  default     = "192.168.0.0/16"
  description = "Address space for created vnet"
}

variable "nsg_name" {
  type    = string
  default = null
  description = "Name of pre-exising NSG. Leave blank to have one created"
}

variable "subnet_names" {
  type        = map(string)
  default     = {}
  description = "Map subnet usage roles to existing subnet names"
  # Example:
  # subnet_names = {
  #   'aks': 'my_aks_subnet', 
  #   'misc': 'my_misc_subnet', 
  #   'netapp': 'my_netapp_subnet'
  # }
}

variable "subnets" {
  type = map(object({
    prefixes                                       = list(string)
    service_endpoints                              = list(string)
    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool
    service_delegations                            = map(object({
      name    = string
      actions = list(string)
    }))
  }))
  default = {
    aks = {
      "prefixes": ["192.168.0.0/23"],
      "service_endpoints": ["Microsoft.Sql"],
      "enforce_private_link_endpoint_network_policies": true,
      "enforce_private_link_service_network_policies": false,
      "service_delegations": {},
    }
    misc = {
      "prefixes": ["192.168.2.0/24"],
      "service_endpoints": ["Microsoft.Sql"],
      "enforce_private_link_endpoint_network_policies": true,
      "enforce_private_link_service_network_policies": false,
      "service_delegations": {},
    }
    netapp = {
      "prefixes": ["192.168.3.0/24"],
      "service_endpoints": [],
      "enforce_private_link_endpoint_network_policies": false,
      "enforce_private_link_service_network_policies": false,
      "service_delegations": {
        netapp = {
          "name"    : "Microsoft.Netapp/volumes"
          "actions" : ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
  }
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider / service account based kube config file"
  type        = bool
  default     = true
}

variable "cluster_node_pool_mode" {
  description = "Flag for predefined cluster node configurations - Values : default, minimal"
  type        = string
  default     = "default"
}

variable "infra_mode" {
  description = "Use Private IP address for cluster API endpoint"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "private"], lower(var.infra_mode))
    error_message = "ERROR: Supported values for `infra_mode` are - standard, private."
  }
}
