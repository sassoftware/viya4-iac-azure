# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default
# values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
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
kubernetes_version         = "1.26"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "Standard_D8s_v4"

# AKS Node Pools config
node_pools = {
  cas = {
    "machine_type" = "Standard_L32s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 1
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule", "zebware.com/zebclient-agent=enabled:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"           = "cas"
      "zebware.com/zebclient-agent-size" = "medium"
    }
  },
  compute = {
    "machine_type" = "Standard_L8s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 1
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=compute:NoSchedule", "zebware.com/zebclient-agent=enabled:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"           = "compute"
      "launcher.sas.com/prepullImage"    = "sas-programming-environment"
      "zebware.com/zebclient-agent-size" = "medium"
    }
  },
  stateless = {
    "machine_type" = "Standard_L16s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 1
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule", "zebware.com/zebclient-agent=enabled:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"           = "stateless"
      "zebware.com/zebclient-agent-size" = "medium"
    }
  },
  stateful = {
    "machine_type" = "Standard_L16s_v3"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 3
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule", "zebware.com/zebclient-agent=enabled:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"           = "stateful"
      "zebware.com/zebclient-agent-size" = "medium"
    }
  }
}

# Jump Box
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"

# Storage for Viya Compute Services
# Supported storage_type values
#    "standard"  - Custom managed NFS Server VM and disks
#    "ha"        - Azure NetApp Files managed service
#    "zebclient" - Zebware storage
storage_type = "zebclient"
# required ONLY when storage_type = zebclient
zebclient_license_key = "A_VALID_LICENSE_KEY"
zebclient_deploy_mode = "direct"
