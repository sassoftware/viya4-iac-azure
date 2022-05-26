# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default values you
# want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "shd-sas" # this is a prefix that you assign for the resources to be created
location = "uaenorth" # e.g., "eastus2"
# ****************  REQUIRED VARIABLES  ****************

# Bring your own existing networking resources
vnet_resource_group_name = "shd-network-rg-n" # RG for BYO resources
vnet_name                = "SHD-INF-VNET-n"           # only needed if using pre-existing
subnet_names             = {
  "aks": "shd-inf-sas-k8s-10.23.8.64-26-n", 
  "misc": "shd-inf-sas-k8s-10.23.8.64-26-n"
  #, "netapp": "" # only needed if using ha storage (aka netapp)
}
# also available as BYO
resource_group_name      = "shd-sas-k8s-rg-n" # RG for aks resources
nsg_name                 = "shd-inf-sas-k8s-10.23.8.64-26-n-nsg"            # 
aks_uai_name             = null #"zandsas-aks-identity" #"<existing-user-defined-identity-name"
aks_identity             = "uai" 

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default. In a SCIM environment,
#          the AzureActiveDirectory service tag must be granted access to port
#          443/HTTPS for the ingress IP address. 

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [] # e.g., ["0.0.0.0/0"]
ssh_public_key              = "~/.ssh/id_rsa.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# Tags can be specified matching your tagging strategy.
tags = {} # for example: { "owner|email" = "<you>@<domain>.<com>", "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {
    sku_name                     = "GP_Gen5_32"
    storage_mb                   = 51200
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false
    administrator_login          = "pgadmin"
    administrator_password       = "1tsAB3aut1fulDay"
    server_version               = "11"
    ssl_enforcement_enabled      = true
    # postgresql_configurations    = { foo = "true", bar = "false" }
  }
}

# Azure Container Registry config
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = false

# AKS config
kubernetes_version         = "1.21.7"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "Standard_D8s_v3" # "Standard_D8s_v4" # Not in UAE

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
  }
}

# Jump Server
create_jump_public_ip = false
jump_vm_admin        = "edcadmin"
jump_vm_machine_type = "Standard_B2s"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "edcadmin"
nfs_vm_machine_type  = "Standard_D8s_v4" # Not in UAE
nfs_raid_disk_size   = 128
nfs_raid_disk_type   = "Standard_LRS"

# Azure Monitor
create_aks_azure_monitor = false

# My additions
default_nodepool_availability_zones = []
node_pools_proximity_placement = true
node_pools_availability_zone   = ""
