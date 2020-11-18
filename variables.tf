variable client_id {}

variable client_secret {}

variable subscription_id {}
variable tenant_id {}

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
  description = "A prefix used in the name for all the Azure resources created by this script. The prefix string must start with lowercase letter and contain only alphanumeric characters and hyphen or dash(-), but can not start or end with '-'."
  type        = string

  validation {
    condition     = can(regex("^[a-z][-0-9a-zA-Z]*[0-9a-zA-Z]$", var.prefix)) && length(var.prefix) > 2 && length(var.prefix) < 21
    error_message = "ERROR: Value of 'prefix'\n * must contain at least one alphanumeric character and at most 20 characters\n * can only contain letters, numbers, and hyphen or dash(-), but can't start or end with '-'."
  }
}
variable "location" {
  description = "The Azure Region to provision all resources in this script"
  default     = "East US"
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "node_vm_admin" {
  description = "OS Admin User for VMs of AKS Cluster nodes"
  default     = "azureuser"
}

variable "default_nodepool_vm_type" {
  default = "Standard_D4_v2"
}
variable "kubernetes_version" {
  description = "The AKS cluster K8s version"
  default     = "1.18.8"
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
  default     = false
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
  default     = null
}

variable "create_jump_public_ip" {
  default = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM"
  default     = "jumpuser"
}

variable "storage_type" {
  type    = string
  default = "standard"

  validation {
    condition     = contains(["dev", "standard", "ha"], lower(var.storage_type))
    error_message = "ERROR: Supported value for `storage_type` are - dev, standard, ha."
  }
}

variable "create_nfs_public_ip" {
  default = false
}

variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM, when storage_type=standard"
  default     = "nfsuser"
}

variable "nfs_raid_disk_size" {
  description = "Size in Gb for each disk of the RAID5 cluster, when storage_type=standard"
  default     = 128
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
    node_taints  = list(string)
    node_labels  = map(string)
  }))

  default = {
    cas = {
      "machine_type" = "Standard_E16s_v3"
      "os_disk_size" = 200
      "min_nodes"    = 0
      "max_nodes"    = 5
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
      "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateful"
      }
    }
  }
}
