# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default
# values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# Values for these required variables MUST be provided
prefix   = "<prefix-value>"         # this is a prefix that you assign for the resources to be created
location = "<azure-location-value>" # e.g., "eastus2"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
ssh_public_key              = "~/.ssh/id_rsa.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# Tags can be specified matching your tagging strategy.
tags = {} # for example: { "owner|email" = "<you>@<domain>.<com>", "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {},
}

# Azure Container Registry config
create_container_registry        = false
container_registry_sku           = "Standard"
container_registry_admin_enabled = false

# AKS config
kubernetes_version         = "1.23.8"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "Standard_D8s_v4"

## Azure Proximity Placement / Availability Zone config
#  !NOTE! - If proximity placement groups are required for your deployment
#           please refer to the user doc for more information and limitations
#           this feature imposes on deployment
#
#  Link - https://github.com/sassoftware/viya4-iac-azure/blob/main/docs/user/ProximityPlacementGroup.md
#
node_pools_proximity_placement = true
node_pools_availability_zone   = ""

# AKS Node Pools config
node_pools = {
  cas = {
    "machine_type" = "Standard_E16s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 1
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
  },
  compute = {
    "machine_type" = "Standard_E16s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 1
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
  },
  stateless = {
    "machine_type" = "Standard_D16s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 2
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
  },
  stateful = {
    "machine_type" = "Standard_D8s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 3
    "max_nodes"    = 3
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
  }
}

# Jump Box
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_vm_zone          = 1

nfs_raid_disk_size = 128
nfs_raid_disk_type = "Standard_LRS"
nfs_raid_disk_zone = "1"
