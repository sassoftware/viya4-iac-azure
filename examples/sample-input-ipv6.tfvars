# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default
# values you want to change.

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

# Tags can be specified matching your tagging strategy.
tags = {} # for example: { "owner|email" = "<you>@<domain>.<com>", "key1" = "value1", "key2" = "value2" }

# *** IPv6 DUAL-STACK CONFIGURATION ***
# REQUIREMENTS: Azure CNI Overlay mode (aks_network_plugin="azure", aks_network_plugin_mode="overlay")
enable_ipv6             = true
aks_network_plugin      = "azure"
aks_network_plugin_mode = "overlay"

# IPv6 Address Space Configuration:
# vnet_ipv6_address_space = "fd00:1234:5678::/48" # Default: ULA range (production-safe for internal clusters)
# aks_pod_ipv6_cidr       = "fd00:10:244::/64"     # Default: ULA range (production-safe overlay)
# aks_service_ipv6_cidr   = "fd00:10:0::/108"      # Default: ULA range (production-safe overlay)
# NOTE: VNet subnet IPv6 ranges are auto-calculated: first /64 (aks), second /64 (misc)
#
# ⚠️  IPv6 PREFIX SELECTION FOR PRODUCTION:
# The defaults use Unique Local Addresses (ULA) fd00::/8 range which is:
#   Production-ready for internal-only clusters
#   Private and isolated (similar to RFC 1918 for IPv4)
#   NOT routable on the public internet
#
# For internet-facing clusters with external IPv6 connectivity:
#   1. Azure-assigned prefix: Contact Azure support for a globally routable /48 allocation
#   2. Organization prefix: Use your company's IPv6 allocation from ISP/RIR
#
# For customizing ULA prefix (recommended for production):
#   - Generate unique random bits: https://www.unique-local-ipv6.com/
#   - Example: vnet_ipv6_address_space = "fd00:abcd:ef01::/48"
#
# DO NOT USE: 2001:db8::/32 range - reserved for documentation only (RFC 3849)

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

# AKS config
kubernetes_version         = "1.32"
default_nodepool_min_nodes = 2
default_nodepool_vm_type   = "Standard_D4_v5"

# AKS Node Pools config - minimal
cluster_node_pool_mode = "minimal"
node_pools = {
  cas = {
    "machine_type"          = "Standard_E4s_v5"
    "os_disk_size"          = 200
    "min_nodes"             = 0
    "max_nodes"             = 5
    "max_pods"              = 110
    "node_taints"           = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
  },
  generic = {
    "machine_type"          = "Standard_D8s_v5"
    "os_disk_size"          = 200
    "min_nodes"             = 0
    "max_nodes"             = 5
    "max_pods"              = 110
    "node_taints"           = []
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
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
