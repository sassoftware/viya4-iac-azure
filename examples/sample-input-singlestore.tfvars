# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default values you
# want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "<prefix-value>" # this is a prefix that you assign for the resources to be created
location = "<azure-location-value>" # e.g., "eastus2"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default. In a SCIM environment,
#          the AzureActiveDirectory service tag must be granted access to port
#          443/HTTPS for the ingress IP address. 

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
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = false

# AKS config
kubernetes_version         = "1.23.8"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "Standard_D8s_v4"

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
    "min_nodes"    = 1
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
    "min_nodes"    = 1
    "max_nodes"    = 3
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
  },
  singlestore = {
    "machine_type" = "Standard_E16ds_v5"         
    "os_disk_size" = 200
    "min_nodes" = 0
    "max_nodes" = 7
    "max_pods" = 110
    "node_taints" = ["workload.sas.com/class=singlestore:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "singlestore"
    }
  }
}

# Jump Server
create_jump_public_ip = true
jump_vm_admin        = "jumpuser"
jump_vm_machine_type = "Standard_B2s"

# Storage for Viya Compute Services
# Supported storage_type values
#    "standard" - Custom managed NFS Server VM and disks
#    "ha"     - Azure NetApp Files managed service

## Standard storage type
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_vm_machine_type  = "Standard_D8s_v4"
nfs_raid_disk_size   = 128
nfs_raid_disk_type   = "Standard_LRS"

## HA storage type
# storage_type = "ha"
# # required ONLY when storage_type = ha for Azure NetApp Files service
# netapp_service_level    = "Premium"
# netapp_size_in_tb       = 4
# netapp_network_features = "Standard"    # For SingleStore configuration with ha storage 'netapp_network_features' should be set to 'Standard'

# SingleStore configuration
aks_network_plugin = "azure"

# Subnets for SingleStore using azure network plugin
subnets = {
  aks = {
    "prefixes": ["192.168.0.0/21"],
    "service_endpoints": ["Microsoft.Sql"],
    "private_endpoint_network_policies_enabled": false,
    "private_link_service_network_policies_enabled": false,
    "service_delegations": {},
  }
  misc = {
    "prefixes": ["192.168.8.0/24"],
    "service_endpoints": ["Microsoft.Sql"],
    "private_endpoint_network_policies_enabled": false,
    "private_link_service_network_policies_enabled": false,
    "service_delegations": {},
  }
  ## If using ha storage then the following is also added
  netapp = {
    "prefixes": ["192.168.9.0/24"],
    "service_endpoints": [],
    "private_endpoint_network_policies_enabled": false,
    "private_link_service_network_policies_enabled": false,
    "service_delegations": {
      netapp = {
        "name"    : "Microsoft.Netapp/volumes"
        "actions" : ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}
