# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default values you
# want to change.
#
# MULTI-AZ WITH AZURE FILES ZRS - RECOMMENDED FOR PRODUCTION
# This configuration uses Azure Files with Zone-Redundant Storage (ZRS) which provides:
# - ✅ Automatic cross-zone failover (RTO < 2 minutes)
# - ✅ Zone-redundant storage (meets SAS multi-AZ requirements)
# - ✅ Fully managed service (no VMs to maintain)
# - ✅ Single endpoint (no DNS updates needed during failover)
#
# Compare with:
# - sample-input-multizone.tfvars (uses Azure NetApp Files - manual failover required)
# - sample-input.tfvars (single-zone NFS VM - not recommended for multi-AZ)

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "viya-multiaz-zrs"
location = "eastus"  # or centralus, westus2, etc.
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = ["149.173.0.0/16"]  # Update with your IP ranges
ssh_public_key              = "~/.ssh/id_rsa.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# Tags for resource organization
tags = {
  "resourceowner" = "your.name@sas.com"
  "jiraticketid"  = "PSCLOUD-388"
  "environment"   = "production"
  "ha-type"       = "multi-az-zrs"
}

# ============================================================================
# STORAGE: AZURE FILES WITH ZONE-REDUNDANT STORAGE (ZRS)
# ============================================================================
# Azure Files ZRS is the RECOMMENDED storage option for multi-AZ deployments
# Provides automatic failover with RTO < 2 minutes

storage_type = "zrs"  # Zone-Redundant Storage (automatic failover)

# Azure Files configuration
azure_files_storage_account_tier = "Premium"  # Premium required for NFS 4.1
azure_files_share_name           = "viya"
azure_files_quota_gb             = 5120  # 5TB (adjust based on your needs)
azure_files_create_private_endpoint = true  # Secure VNet access

# Storage Performance Reference (for 5TB Premium):
# - Sequential Read:  ~300 MB/s
# - Sequential Write: ~250 MB/s
# - Random IOPS:      ~10,000
# - Cost:             ~$1,882/month (East US)
# - Automatic Failover: Yes (RTO < 2 minutes)

# ============================================================================
# POSTGRESQL: ZONE-REDUNDANT HIGH AVAILABILITY
# ============================================================================
# PostgreSQL Flexible Server with automatic zone-redundant HA

postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"  # Automatic failover
    availability_zone         = "1"               # Primary in zone 1
    standby_availability_zone = "2"               # Standby in zone 2
  }
}

# ============================================================================
# AKS: MULTI-AVAILABILITY ZONE CONFIGURATION
# ============================================================================

kubernetes_version         = "1.32"
default_nodepool_min_nodes = 3  # Minimum 3 for multi-AZ (one per zone)
default_nodepool_vm_type   = "Standard_E8s_v5"

# Spread default node pool across all 3 zones
default_nodepool_availability_zones = ["1", "2", "3"]

# AKS Node Pools - Multi-AZ Configuration
node_pools = {
  # CAS node pool - SINGLE ZONE for MPP performance
  cas = {
    "machine_type" = "Standard_E16ds_v5"
    "os_disk_size" = 200
    "min_nodes"    = 3  # All 3 nodes in same zone
    "max_nodes"    = 5
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "availability_zones" = ["1"]  # Single zone for low-latency MPP
  },
  
  # Compute node pool - MULTI-ZONE for HA
  compute = {
    "machine_type" = "Standard_D4ds_v5"
    "os_disk_size" = 200
    "min_nodes"    = 3  # One per zone (1, 2, 3)
    "max_nodes"    = 6
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "availability_zones" = ["1", "2", "3"]  # Span all zones
  },
  
  # Stateless node pool - MULTI-ZONE for HA
  stateless = {
    "machine_type" = "Standard_D4s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 3  # One per zone (1, 2, 3)
    "max_nodes"    = 9
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
    "availability_zones" = ["1", "2", "3"]  # Span all zones
  },
  
  # Stateful node pool - MULTI-ZONE for HA
  stateful = {
    "machine_type" = "Standard_D4s_v5"
    "os_disk_size" = 200
    "min_nodes"    = 3  # One per zone (1, 2, 3)
    "max_nodes"    = 6
    "max_pods"     = 110
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
    "availability_zones" = ["1", "2", "3"]  # Span all zones
  }
}

# ============================================================================
# JUMP SERVER (Optional)
# ============================================================================

create_jump_public_ip = true
jump_vm_admin         = "jumpuser"
jump_vm_machine_type  = "Standard_B2s"

# ============================================================================
# AZURE CONTAINER REGISTRY (Optional)
# ============================================================================

create_container_registry        = false
container_registry_sku           = "Standard"
container_registry_admin_enabled = false

# ============================================================================
# MULTI-AZ FAILOVER VALIDATION
# ============================================================================
#
# To validate automatic failover:
#
# 1. Check zone distribution:
#    kubectl get nodes -L topology.kubernetes.io/zone
#
# 2. Simulate zone failure:
#    kubectl cordon $(kubectl get nodes -l topology.kubernetes.io/zone=eastus-1 -o name)
#
# 3. Verify storage remains accessible:
#    kubectl get pods -o wide -w
#    # Pods should reschedule to zones 2 & 3, storage remains available
#
# 4. Cleanup:
#    kubectl uncordon $(kubectl get nodes -l topology.kubernetes.io/zone=eastus-1 -o name)
#
# Expected Results:
# - Storage: Automatic failover, no manual intervention (RTO < 2 min)
# - PostgreSQL: Automatic failover to standby zone (RTO < 2 min)
# - Pods: Reschedule to surviving zones automatically
# - CAS: Unavailable until zone 1 recovers (by design - MPP in single zone)
#
# ============================================================================
# COST ESTIMATE (East US region, approximate)
# ============================================================================
#
# Azure Files Premium ZRS:
#   5TB storage:          $1,792/month
#   Transactions:         ~$90/month
#   Private endpoint:     ~$7/month
#   Subtotal:             $1,889/month
#
# PostgreSQL Zone-Redundant:
#   GP_Standard_D4ds_v5:  ~$350/month
#   Storage (128GB):      ~$16/month
#   Backup (128GB):       ~$3/month
#   Subtotal:             $369/month
#
# AKS Nodes (example with min_nodes):
#   System (3x E8s_v5):   ~$1,050/month
#   CAS (3x E16ds_v5):    ~$2,100/month
#   Compute (3x D4ds_v5): ~$420/month
#   Stateless (3x D4s_v5):~$315/month
#   Stateful (3x D4s_v5): ~$315/month
#   Subtotal:             $4,200/month
#
# TOTAL ESTIMATED COST:   ~$6,458/month
#
# Compare with NetApp:    ~$6,600/month (with manual failover)
# Compare with single-AZ: ~$3,500/month (no HA)
#
# Cost savings vs NetApp: ~$142/month (~2%)
# Additional cost for HA: ~$2,958/month (~85% increase vs single-AZ)
#
# ============================================================================
# BENEFITS SUMMARY
# ============================================================================
#
# ✅ Automatic Failover:
#    - Storage RTO < 2 minutes (vs 15-60 min with NetApp manual)
#    - PostgreSQL RTO < 2 minutes (automatic zone-redundant HA)
#    - No manual intervention required
#
# ✅ SAS Compliance:
#    - Meets official multi-AZ requirements (zone-redundant storage)
#    - Automatic failover capability as required
#
# ✅ Operational Benefits:
#    - No runbook execution needed during zone failures
#    - Fully managed service (no VM patching/maintenance)
#    - Single storage endpoint (no DNS updates)
#
# ✅ Cost-Effective:
#    - Slightly cheaper than NetApp (~2% savings)
#    - Better price/performance for automatic failover
#
# ⚠️ Performance Tradeoff:
#    - Lower IOPS than NetApp Premium (10k vs 100k)
#    - Adequate for most workloads
#    - Consider NetApp if ultra-high performance required
#
# ============================================================================
