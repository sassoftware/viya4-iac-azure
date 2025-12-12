# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default values you
# want to change.

# ========================================================================
# MULTI-AVAILABILITY ZONE DEPLOYMENT EXAMPLE
# ========================================================================
# This example configures an AKS cluster spanning multiple availability zones.
# 
# ⚠️  CRITICAL STORAGE LIMITATION:
# SAS requires zone-redundant storage (ZRS) for multi-AZ deployments.
# The storage options in this example have limitations:
#
# - NFS Server VM (storage_type="standard") with ZRS disks:
#   ✓ Disk-level redundancy across zones
#   ✗ VM remains in single zone (limited zone failure protection)
#
# - Azure NetApp Files (storage_type="ha") with cross-zone replication:
#   ✓ Data replicated across zones
#   ✗ Requires MANUAL intervention during zone failures (15-60+ min RTO)
#   ✗ Does NOT meet automatic failover requirements
#
# For production multi-AZ deployments requiring automatic failover:
# - Consider external storage solutions (Azure Files with ZRS, etc.)
# - OR accept manual failover procedures with documented runbooks
#
# Reference: https://go.documentation.sas.com/doc/en/sasadmincdc/v_070/itopssr/n1kj7od7zbas1en17vyb6tv39eac.htm
# ========================================================================

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
kubernetes_version         = "1.32"
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

# StandardSSD_ZRS and Premium_ZRS provides zone-redundant storage for high availability.
nfs_raid_disk_type   = "StandardSSD_ZRS" 
os_disk_storage_account_type   = "StandardSSD_ZRS"
# Example configuration for multi-zone AKS deployment.
# Specify the list of availability zones for the default node pool and additional node pools.

default_nodepool_availability_zones = ["1", "2", "3"] 
node_pools_availability_zones       = ["1", "2", "3"]
