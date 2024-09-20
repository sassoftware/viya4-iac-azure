# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default
# values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# Values for these required variables MUST be provided
prefix   = "<prefix-value>" # this is a prefix that you assign for the resources to be created
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

# PostgreSQL

# Postgres config - By having this entry a database server is created. 
#                   Default networking option: Public access (allowed IP addresses) is enabled
#                   If you do not need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {},
}

# To use Private access (VNet Integration) remove the 'postgres_servers' block above and uncomment the blocks below:
# postgres_servers and subnets

# postgres_servers = {
#   default = {
#     connectivity_method = "private"
#   }
# }
#
# # Subnet for PostgreSQL
# subnets = {
#   aks = {
#     "prefixes" : ["192.168.0.0/23"],
#     "service_endpoints" : ["Microsoft.Sql"],
#     "private_endpoint_network_policies" : "Enabled",
#     "private_link_service_network_policies_enabled" : false,
#     "service_delegations" : {},
#   }
#   misc = {
#     "prefixes" : ["192.168.2.0/24"],
#     "service_endpoints" : ["Microsoft.Sql"],
#     "private_endpoint_network_policies" : "Enabled",
#     "private_link_service_network_policies_enabled" : false,
#     "service_delegations" : {},
#   }
#   netapp = {
#     "prefixes" : ["192.168.3.0/24"],
#     "service_endpoints" : [],
#     "private_endpoint_network_policies" : "Disabled",
#     "private_link_service_network_policies_enabled" : false,
#     "service_delegations" : {
#       netapp = {
#         "name" : "Microsoft.Netapp/volumes"
#         "actions" : ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
#       }
#     }
#   }
#   postgresql = {
#     "prefixes": ["192.168.4.0/24"],
#     "service_endpoints": ["Microsoft.Sql"],
#     "private_endpoint_network_policies": "Enabled",
#     "private_link_service_network_policies_enabled": false,
#     "service_delegations": {
#       flexpostgres = {
#         "name"    : "Microsoft.DBforPostgreSQL/flexibleServers"
#         "actions" : ["Microsoft.Network/virtualNetworks/subnets/join/action"]
#       }
#     }
#   }
# }

# Azure Container Registry config
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = false

# AKS config
kubernetes_version         = "1.29"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "Standard_E8s_v5"

# AKS Node Pools config
node_pools = {
  cas = {
    "machine_type" = "Standard_E16ds_v5"
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
    "machine_type" = "Standard_D4ds_v5"
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
    "machine_type" = "Standard_D4s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 4
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
  },
  stateful = {
    "machine_type" = "Standard_D4s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 2
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
  }
}

# Jump Server
create_jump_public_ip = true
jump_vm_admin        = "jumpuser"
jump_vm_machine_type = "Standard_B2s"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_vm_machine_type  = "Standard_D4s_v5"
nfs_raid_disk_size   = 256
nfs_raid_disk_type   = "Standard_LRS"
