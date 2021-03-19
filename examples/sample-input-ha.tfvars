# !NOTE! - These are only a subset of variables.tf provided for sample usage.
# Customize this file to add any variables from 'variables.tf' that you want
# to change (override) their default values .
# Reference `viya4-iac-azure/docs/CONFIG-VARS.md` for more information

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "<prefix-value>" # this is a prefix that you assign for the resources to be created
location = "<azure-location-value>" # e.g., "eastus2"
ssh_public_key = "~/.ssh/id_rsa.pub" # Name of file with public ssh key for connecting to the VMs
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
# **************  RECOMMENDED  VARIABLES  ***************

# Tags for all taggable items in your cluster.
tags = {} # e.g., { "resourceowner" = "<you>@<domain>.<com>", "key1" = "value1", "key2" = "value2" }

# Azure Postgres config
create_postgres                  = true # set this to "false" when using internal Crunchy Postgres
postgres_ssl_enforcement_enabled = false
postgres_administrator_password  = "mySup3rS3cretPassw0rd"

# Azure Container Registry config
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = false
container_registry_geo_replica_locs = null

# AKS config
kubernetes_version         = "1.18.14"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "Standard_D8s_v4"

# AKS Node Pools config
node_pools = {
  cas = {
    "machine_type" = "Standard_E16s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 3
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
  },
  compute = {
    "machine_type" = "Standard_E16s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 3
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
    "min_nodes"    = 2
    "max_nodes"    = 3
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
    "min_nodes"    = 2
    "max_nodes"    = 3
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
  },
  stateful = {
    "machine_type" = "Standard_D8s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 2
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

# Storage for Viya Compute Services
# Supported storage_type values
#    "standard" - Custom managed NFS Server VM and disks
#    "ha"     - Azure NetApp Files managed service
storage_type = "ha"
# required ONLY when storage_type = ha for Azure NetApp Files service
netapp_service_level = "Premium"
netapp_size_in_tb    = 4

# Azure Monitor
create_aks_azure_monitor = false
