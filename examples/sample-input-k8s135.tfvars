# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default
# values you want to change.

# This example configuration is specifically for Kubernetes 1.35+ deployments
# on Azure AKS, addressing known networking issues with kubenet CNI plugin.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "<prefix-value>" # this is a prefix that you assign for the resources to be created
location = "<azure-location-value>" # e.g., "eastus2"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
ssh_public_key              = "~/.ssh/id_rsa.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# ************** KUBERNETES 1.35+ REQUIRED **************
# These settings are REQUIRED for Kubernetes 1.35+ to avoid hairpin networking
# issues where pods cannot communicate with their own service endpoints.
# This resolves FNDTRG-278 and related issues.
kubernetes_version      = "1.35"  # or specific patch version like "1.35.0"
aks_network_plugin      = "azure"
aks_network_plugin_mode = "overlay"

# Optional: Configure pod CIDR for overlay network (default is used if not specified)
# aks_pod_cidr = "10.244.0.0/16"

# Optional: Network policy configuration (works with Azure CNI Overlay)
# aks_network_policy = "azure"  # or "calico"
# ************** KUBERNETES 1.35+ REQUIRED **************

# Tags can be specified matching your tagging strategy.
tags = {} # for example: { "owner|email" = "<you>@<domain>.<com>", "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
# postgres_servers = {
#   default = {},
# }

# Azure Container Registry config
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = false
container_registry_geo_replica_locs = null

# AKS config
kubernetes_version         = "1.35"
default_nodepool_min_nodes = 2
default_nodepool_max_nodes = 5

## AKS Node Pools config
node_pools = {
  cas = {
    "machine_type" = "Standard_E16s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
  },
  compute = {
    "machine_type" = "Standard_E16s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
  },
  connect = {
    "machine_type" = "Standard_E16s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=connect:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "connect"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
  },
  stateless = {
    "machine_type" = "Standard_D8s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
  },
  stateful = {
    "machine_type" = "Standard_D8s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
  }
}

# Jump Server
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"

# NFS Server
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_raid_disk_size   = 128
