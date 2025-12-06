# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default values you
# want to change.
#
# MULTI-AZ ENHANCED VERSION - Compare with sample-input-multizone.tfvars
# This configuration enables TRUE multi-AZ resilience with:
# - Zone-redundant PostgreSQL HA
# - Cross-zone NetApp replication
# - Multi-zone AKS node pools

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

# ✅ MULTI-AZ POSTGRESQL CONFIGURATION
# Postgres config with Zone-Redundant High Availability
# Primary in Zone 1, Standby in Zone 2 for automatic failover
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"  # Enable zone-redundant HA
    availability_zone         = "1"               # Primary zone
    standby_availability_zone = "2"               # Standby zone (must differ from primary)
  }
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

# ✅ OPTION 1: MULTI-AZ WITH AZURE NETAPP FILES (Recommended for production)
# Storage for SAS Viya CAS/Compute with Cross-Zone Replication
storage_type = "ha"

# NetApp configuration with cross-zone replication
netapp_service_level                 = "Premium"
netapp_size_in_tb                    = 4
netapp_network_features              = "Standard"  # Required for cross-zone replication

# ✅ Multi-AZ NetApp configuration
netapp_availability_zone             = "1"         # Primary volume in Zone 1
netapp_enable_cross_zone_replication = true        # Enable cross-zone replication
netapp_replication_zone              = "2"         # Replica volume in Zone 2
netapp_replication_frequency         = "10minutes" # Replication frequency (10minutes, hourly, daily)

# ✅ OPTION 2: STANDARD NFS WITH ZONE-REDUNDANT STORAGE (Limited HA)
# Uncomment these lines if using standard NFS instead of NetApp
# NOTE: With standard storage, the NFS VM is still in a single zone
# Even with ZRS disks, the VM won't auto-restart in another zone during zone failure
# Consider using Azure Site Recovery for full VM-level DR

# storage_type = "standard"
# create_nfs_public_ip = false
# nfs_vm_admin         = "nfsuser"
# nfs_vm_machine_type  = "Standard_D4s_v5"
# nfs_raid_disk_size   = 256
# nfs_vm_zone          = "1"                     # NFS VM in Zone 1 (single point of failure)

# ✅ Zone-redundant storage disks (survives zone failure but VM doesn't auto-recover)
# nfs_raid_disk_type            = "StandardSSD_ZRS"  # Zone-redundant data disks
# os_disk_storage_account_type  = "StandardSSD_ZRS"  # Zone-redundant OS disk

# ✅ MULTI-ZONE AKS CONFIGURATION
# Spread AKS node pools across all availability zones
default_nodepool_availability_zones = ["1", "2", "3"] 
node_pools_availability_zones       = ["1", "2", "3"]

# ============================================================================
# SUMMARY OF MULTI-AZ PROTECTION:
# ============================================================================
# 
# ✅ PostgreSQL: Zone-Redundant HA
#    - Primary in Zone 1, Standby in Zone 2
#    - Automatic failover if Zone 1 fails
#    - No data loss, minimal downtime
#
# ✅ Storage (Option 1 - NetApp): Cross-Zone Replication
#    - Primary volume in Zone 1
#    - Replica volume in Zone 2
#    - 10-minute replication frequency
#    - Manual failover required (but data is protected)
#
# ⚠️ Storage (Option 2 - NFS): Limited HA
#    - Zone-redundant disks (ZRS) survive zone failure
#    - BUT: NFS VM is in single zone and won't auto-restart
#    - Requires Azure Site Recovery or manual intervention
#
# ✅ AKS Node Pools: Multi-Zone Distribution
#    - Nodes spread across zones 1, 2, and 3
#    - Continues running if one zone fails
#    - Kubernetes automatically reschedules pods
#
# ============================================================================
# ZONE FAILURE SCENARIO (Zone 1 Fails):
# ============================================================================
#
# With this configuration:
# ✅ PostgreSQL automatically fails over to Zone 2
# ✅ AKS continues running with nodes in Zones 2 and 3
# ✅ NetApp data is safe in Zone 2 replica (manual failover needed)
# ⚠️ Standard NFS requires manual recovery even with ZRS disks
#
# Result: Minimal downtime, no data loss (with NetApp)
# ============================================================================
