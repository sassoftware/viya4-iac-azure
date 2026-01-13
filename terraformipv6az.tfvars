# Customize this file to add any variables from 'CONFIG-VARS.md' whose default
# values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "ipv6az2"
location = "westus2" # e.g., "useast2"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = ["149.173.0.0/16", "194.206.69.176/28", "109.232.56.224/27", "62.255.11.0/29", "88.202.174.192/29", "137.221.139.0/24", "212.103.250.112/29", "88.151.216.240/29", "121.244.109.0/24", "125.21.192.0/29", "121.243.77.24/29", "106.120.85.32/28", "113.34.83.240/29", "192.31.22.0/24", "80.80.4.0/27"]
ssh_public_key = "/.ssh/id_rsa.pub"

# **************  RECOMMENDED  VARIABLES  ***************

# Tags can be specified matching your tagging strategy.
tags = {"resourceowner": "abhishek.kumar@sas.com","jiraticketid" : "PSCLOUD-409"} # e.g., { "key1" = "value1", "key2" = "value2" }

# Create shareable kubeconfig
#create_static_kubeconfig = true

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
 default = {},
}

#Disabled Public Access
postgres_public_access_cidrs = []

# Azure Container Registry config
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = false

# AKS config
kubernetes_version         = "1.32"
default_nodepool_min_nodes = 2
#v3 still has local temp storage
default_nodepool_vm_type   = "Standard_E8s_v5"

# *** IPv6 DUAL-STACK CONFIGURATION ***
enable_ipv6                = true
vnet_address_space         = "192.168.0.0/16"
vnet_ipv6_address_space    = "2001:db8::/48"
aks_pod_ipv6_cidr          = "2001:db8::/64"
aks_service_ipv6_cidr      = "2001:db8:1::/108"
# *** IPv6 DUAL-STACK CONFIGURATION ***
# Note: Subnet IPv6 ranges are auto-calculated using cidrsubnet() from vnet_ipv6_address_space

# AKS Node Pools config - minimal
cluster_node_pool_mode = "standard"
node_pools = {
  cas = {
    "machine_type"          = "Standard_E16ds_v5"
    "os_disk_size"          = 200
    "min_nodes"             = 1
    "max_nodes"             = 1
    "max_pods"              = 110
    "node_taints"           = ["workload.sas.com/class=cas:NoSchedule"]
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
    "max_nodes"    = 2
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

# Azure Monitor
create_aks_azure_monitor = false
