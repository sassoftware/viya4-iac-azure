# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want
# to change their default values.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "<prefix-value>"
location                                = "<azure-location-value>" # e.g., "useast2"
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }
# ****************  REQUIRED VARIABLES  ****************

# When a ssh key value is provided it will be used for all VMs or else a ssh key will be auto generated and available in outputs
ssh_public_key                  = "~/.ssh/id_rsa.pub"

# Admins access
default_public_access_cidrs             = []  # e.g., ["123.45.6.89/32"]
cluster_endpoint_public_access_cidrs    = []  # e.g., ["123.45.6.89/32"]
acr_public_access_cidrs                 = []  # e.g., ["123.45.6.89/32"]
vm_public_access_cidrs                  = []  # e.g., ["123.45.6.89/32"]
postgres_public_access_cidrs            = []  # e.g., ["123.45.6.89/32"]

# Azure Postgres config
create_postgres                  = true # set this to "false" when using internal Crunchy Postgres
postgres_ssl_enforcement_enabled = false
postgres_administrator_password  = "mySup3rS3cretPassw0rd"

# Azure Container Registry config
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = "false"
container_registry_geo_replica_locs = null

# AKS config
kubernetes_version                   = "1.18.8"
default_nodepool_node_count          = 2
default_nodepool_vm_type             = "Standard_D4_v2"

# AKS Node Pools config
node_pools = {
  cas = {
    "machine_type" = "Standard_E16s_v3"
    "os_disk_size" = 200
    "min_node_count" = 1
    "max_node_count" = 1
    "node_taints" = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "availability_zones" = ["1", "2", "3"]
  },
  compute = {
    "machine_type" = "Standard_E16s_v3"
    "os_disk_size" = 200
    "min_node_count" = 1
    "max_node_count" = 1
    "node_taints" = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "availability_zones" = ["1", "2", "3"]
  },
  connect = {
    "machine_type" = "Standard_E16s_v3"
    "os_disk_size" = 200
    "min_node_count" = 1
    "max_node_count" = 1
    "node_taints" = ["workload.sas.com/class=connect:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "connect"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "availability_zones" = ["1", "2", "3"]
  },
  stateless = {
    "machine_type" = "Standard_D16s_v3"
    "os_disk_size" = 200
    "min_node_count" = 1
    "max_node_count" = 2
    "node_taints" = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
    "availability_zones" = ["1", "2", "3"]
  },
  stateful = {
    "machine_type" = "Standard_D8s_v3"
    "os_disk_size" = 200
    "min_node_count" = 1
    "max_node_count" = 3
    "node_taints" = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
    "availability_zones" = ["1", "2", "3"]
  }
}

# Jump Box
create_jump_public_ip          = true
jump_vm_admin                  = "jumpuser"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip  = false
nfs_vm_admin          = "nfsuser"
nfs_raid_disk_size    = 128
