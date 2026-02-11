# Multi-Availability Zone Configuration

This document describes the configuration variables for deploying SAS Viya with multi-AZ high availability and disaster recovery capabilities on Azure.

## Table of Contents

- [Multi-Availability Zone Configuration](#multi-availability-zone-configuration)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [PostgreSQL High Availability](#postgresql-high-availability)
  - [Azure NetApp Files Cross-Zone Replication](#azure-netapp-files-cross-zone-replication)
  - [Complete Multi-AZ Example](#complete-multi-az-example)
  - [Validation Rules](#validation-rules)
  - [Zone Failure Scenarios](#zone-failure-scenarios)
  - [Backward Compatibility](#backward-compatibility)
  - [Default Values](#default-values)
  - [Cost Considerations](#cost-considerations)
  - [NFS VM with Zone-Redundant Storage](#nfs-vm-with-zone-redundant-storage)
  - [AKS Node Pool Zone Configuration](#aks-node-pool-zone-configuration)
  - [Multi-AZ Deployment Scenarios](#multi-az-deployment-scenarios)
  - [NetApp Cross-Zone Replication Limitations](#netapp-cross-zone-replication-limitations)
    - [1. Manual Failover Required](#1-manual-failover-required)
    - [2. Recovery Time & Data Loss Objectives](#2-recovery-time--data-loss-objectives)
    - [3. Replica is Read-Only During Normal Operations](#3-replica-is-read-only-during-normal-operations)
    - [4. Network Features Requirement & Cost](#4-network-features-requirement--cost)
    - [5. Replication Direction is One-Way Only](#5-replication-direction-is-one-way-only)
    - [6. Failback Complexity After Zone Recovery](#6-failback-complexity-after-zone-recovery)
    - [7. Dual Capacity Pool Management Overhead](#7-dual-capacity-pool-management-overhead)
    - [8. No Automatic Application Failover](#8-no-automatic-application-failover)
    - [9. Network Latency During Cross-Zone Replication](#9-network-latency-during-cross-zone-replication)
  - [NetApp vs PostgreSQL High Availability Comparison](#netapp-vs-postgresql-high-availability-comparison)
  - [Recommended Architecture](#recommended-architecture)
  - [Best Practices for NetApp Multi-AZ](#best-practices-for-netapp-multi-az)
  - [Limitations Summary](#limitations-summary)
  - [References](#references)

## Overview

The viya4-iac-azure Infrastructure as Code now supports deploying SAS Viya components across multiple Azure availability zones for high availability and disaster recovery.

### What Gets Protected:

| Component | Feature | Status |
| :--- | :--- | :--- |
| PostgreSQL | Zone-redundant high availability | Full automatic failover |
| Azure NetApp Files | Cross-zone replication | Manual failover capable |
| AKS Nodes | Multi-zone node pools | Automatic pod rescheduling |

### What's Optional:

All multi-AZ features are **opt-in**. Existing configurations continue to work without modification. All new variables have safe defaults that maintain single-zone deployments.

---

## PostgreSQL High Availability

Enable zone-redundant high availability for PostgreSQL Flexible Server. When enabled, Azure automatically manages a standby replica in a different availability zone with automatic failover.

### Configuration Variables

Add these fields to your `postgres_servers` configuration:

| Name | Description | Type | Default | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `high_availability_mode` | HA mode: `"ZoneRedundant"`, `"SameZone"`, or `null` to disable | string | `null` | `null` = HA disabled (single zone) |
| `availability_zone` | Primary server availability zone | string | `"1"` | Valid values: `"1"`, `"2"`, `"3"` |
| `standby_availability_zone` | Standby server availability zone | string | `"2"` | **Must differ from `availability_zone` when using ZoneRedundant** |

### Usage Example

```hcl
postgres_servers = {
  default = {
    sku_name                     = "GP_Standard_D4s_v3"
    administrator_login          = "pgadmin"
    administrator_password       = "YourPassword123!"
    
    # Enable Zone-Redundant High Availability
    high_availability_mode       = "ZoneRedundant"
    availability_zone            = "1"          # Primary in zone 1
    standby_availability_zone    = "2"          # Standby in zone 2
    
    # Other PostgreSQL settings...
    storage_mb                   = 32768
    backup_retention_days        = 7
  }
}
```

### PostgreSQL HA Behavior

When `high_availability_mode = "ZoneRedundant"`:

| Aspect | Behavior |
| :--- | :--- |
| **Primary Server** | Deployed in `availability_zone` |
| **Standby Server** | Deployed in `standby_availability_zone` |
| **Replication** | Synchronous (no data loss) |
| **Failover** | Automatic |

### Validation

The configuration validates that:
- `high_availability_mode` is one of: `"ZoneRedundant"`, `"SameZone"`, or `null`
- `availability_zone` is one of: `"1"`, `"2"`, `"3"`, or `null`
- `standby_availability_zone` is one of: `"1"`, `"2"`, `"3"`, or `null`
- When `high_availability_mode = "ZoneRedundant"`: `standby_availability_zone` must differ from `availability_zone`

**Validation Failure Example:**
```hcl
# ERROR: Same zones for ZoneRedundant mode
high_availability_mode    = "ZoneRedundant"
availability_zone         = "1"
standby_availability_zone = "1"  # ERROR: Must differ from primary

# Error message:
# When high_availability_mode is 'ZoneRedundant', standby_availability_zone 
# must differ from availability_zone...
```

---

## Azure NetApp Files Cross-Zone Replication

Enable cross-zone replication for Azure NetApp Files storage. Data is replicated to a volume in a different availability zone for disaster recovery. When enabled, the IaC automatically provisions a **Private DNS Zone** that provides a stable hostname for NFS mounts, eliminating the need for static IP addresses and simplifying failover recovery.

### Configuration Variables

| Name | Description | Type | Default | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `netapp_availability_zone` | Primary volume availability zone | string | `"1"` | Valid values: `"1"`, `"2"`, `"3"` |
| `netapp_enable_cross_zone_replication` | Enable cross-zone replication and DNS zone | bool | `false` | Requires `netapp_network_features = "Standard"`. Automatically creates Private DNS Zone. |
| `netapp_replication_zone` | Replica volume availability zone | string | `"2"` | **Must differ from `netapp_availability_zone`** |
| `netapp_replication_frequency` | Replication frequency | string | `"10minutes"` | Options: `"10minutes"`, `"hourly"`, `"daily"` |
| `netapp_network_features` | Network features required for replication | string | `"Basic"` | Must be `"Standard"` when replication is enabled |
| `netapp_dns_zone_name` | Private DNS Zone name for NFS hostname | string | `"sas-viya.internal"` | Stable DNS zone for failover resilience |
| `netapp_dns_record_name` | DNS A record name for NFS endpoint | string | `"nfs"` | FQDN: `<record>.<zone>` (e.g., `nfs.sas-viya.internal`) |

### Usage Example

```hcl
# Enable NetApp Cross-Zone Replication with DNS
storage_type                         = "ha"
netapp_service_level                 = "Premium"
netapp_size_in_tb                    = 4
netapp_network_features              = "Standard"     # Required for cross-zone replication

# Multi-AZ Configuration
netapp_availability_zone             = "1"            # Primary volume in zone 1
netapp_enable_cross_zone_replication = true           # Enables CZR + DNS Zone
netapp_replication_zone              = "2"            # Replica in zone 2
netapp_replication_frequency         = "10minutes"    # Replicate every 10 minutes

# Optional: Customize DNS (defaults shown)
netapp_dns_zone_name   = "sas-viya.internal"          # DNS zone name
netapp_dns_record_name = "nfs"                        # DNS record name
# Result: NFS mount at nfs.sas-viya.internal
```

### DNS-Based Failover Resilience

**Key Benefits:**

1. **Stable Hostname**: Storage classes reference `nfs.sas-viya.internal` instead of a static IP
2. **Simplified Recovery**: Update DNS A record instead of recreating PVCs
3. **Automatic Provisioning**: DNS zone, VNet link, and A record created when CZR is enabled

**Resources Created:**
- **Private DNS Zone**: `<netapp_dns_zone_name>` (default: `sas-viya.internal`)
- **VNet Link**: Connects DNS zone to your VNet for resolution
- **DNS A Record**: `<netapp_dns_record_name>.<netapp_dns_zone_name>` → Primary volume IP

**Storage Class Configuration:**

The `rwx_filestore_endpoint` output automatically returns the DNS hostname when CZR is enabled:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sas-nfs-storageclass
provisioner: kubernetes.io/nfs
parameters:
  server: nfs.sas-viya.internal  # DNS hostname, not static IP
  path: /export
```

### CZR Failover Recovery

When an ANF zone failure occurs, follow these steps to recover:

> **⚠️ CRITICAL**: Existing pods will NOT automatically reconnect after DNS update. Service restart is **MANDATORY**. NFS clients cache the resolved IP at mount time and do not re-resolve DNS until remounted.

**1. Break Replication Peering (Make Replica Read-Write)**
```bash
# IMPORTANT: Break replication to promote replica to read-write
az netappfiles volume replication remove \
  --resource-group <rg-name> \
  --account-name <account-name> \
  --pool-name <pool-name> \
  --volume-name <volume-name>-replica

# Wait for replication break to complete (check status)
az netappfiles volume replication status \
  --resource-group <rg-name> \
  --account-name <account-name> \
  --pool-name <pool-name> \
  --volume-name <volume-name>-replica
# Wait until status shows "Broken" or "Uninitialized"
```

**2. Identify New Primary IP**
```bash
# Get replica volume IP (becomes new primary)
terraform output netapp_replica_ip
# Output: ["10.X.Y.Z"]
```

**3. Update DNS A Record**
```bash
# Using Azure CLI
DNS_ZONE=$(terraform output -raw netapp_dns_hostname | cut -d. -f2-)
RECORD_NAME=$(terraform output -raw netapp_dns_hostname | cut -d. -f1)
NEW_IP=$(terraform output -raw netapp_replica_ip | jq -r '.[0]')
RG_NAME="<your-resource-group>"

az network private-dns record-set a update \
  --resource-group $RG_NAME \
  --zone-name $DNS_ZONE \
  --name $RECORD_NAME \
  --set aRecords[0].ipv4Address=$NEW_IP

# Verify DNS updated
nslookup nfs.sas-viya.internal
```

**4. Restart ALL Viya Services (REQUIRED)**
```bash
# IMPORTANT: Scale down ALL deployments and statefulsets to force remount
# Partial restart will cause split-brain issues (some pods on old IP, some on new IP)

# Scale down deployments
kubectl scale deployment --all --replicas=0 -n <viya-namespace>

# Scale down statefulsets (CAS, RabbitMQ, Consul, Redis, etc.)
kubectl scale statefulset --all --replicas=0 -n <viya-namespace>

# Wait for all pods to terminate
kubectl wait --for=delete pod --all -n <viya-namespace> --timeout=600s

# Scale up deployments
kubectl scale deployment --all --replicas=1 -n <viya-namespace>

# Scale up statefulsets back to original replica counts
kubectl scale statefulset sas-cacheserver --replicas=3 -n <viya-namespace>
kubectl scale statefulset sas-cas-server-default --replicas=3 -n <viya-namespace>
# ... scale other statefulsets as needed
```

**5. Validate Recovery**
```bash
# Verify all pods are running
kubectl get pods -n <viya-namespace>

# Verify NFS mounts point to NEW IP (should show addr=<NEW_IP>)
kubectl exec -it <pod-name> -n <viya-namespace> -- mount | grep nfs.sas-viya.internal

# Example expected output:
# nfs.sas-viya.internal:/export/pvs/... on /path type nfs4 (...,addr=192.168.3.5)
```

**Troubleshooting:**

| Issue | Symptom | Root Cause | Solution |
|-------|---------|------------|----------|
| CAS pods cycling | CAS controller/backup-controller in CrashLoopBackOff | Mixed IP states: some pods on old IP, some on new IP | Restart ALL CAS pods together using StatefulSet scale down/up |
| New pods mount, old pods fail | Some pods work, others show "access denied" | Old pods still using old IP (blocked by export policy) | Complete service restart required |
| Pods stuck in ContainerCreating | Mount errors: "connection timed out" | DNS not propagated or old IP still in use | Wait 5 min for DNS TTL, verify nslookup, restart pods |

**Key Terraform Outputs for Recovery:**

| Output | Description | Use Case |
|--------|-------------|----------|
| `netapp_dns_hostname` | Stable DNS hostname (e.g., `nfs.sas-viya.internal`) | Reference in storage classes |
| `netapp_primary_ip` | Current primary volume IP | Pre-failover reference |
| `netapp_replica_ip` | Current replica volume IP | New primary IP after failover |
| `netapp_dns_zone_id` | Private DNS Zone resource ID | Automation scripts |

**Retrieve Terraform Outputs:**
```bash
# Get DNS hostname
terraform output -raw netapp_dns_hostname
# Output: nfs.sas-viya.internal

# Get primary volume IP
terraform output -json netapp_primary_ip
# Output: ["192.168.3.4"]

# Get replica volume IP
terraform output -json netapp_replica_ip
# Output: ["192.168.3.5"]

# Get DNS zone ID
terraform output -raw netapp_dns_zone_id
```

**Important Notes:**
- **CRITICAL**: Both primary and replica volumes use **identical export paths** (e.g., `/export`). **Design Decision**: No `-replica` suffix is used on the replica volume path to enable seamless DNS-based failover. After DNS update, storage classes continue using the same mount path without requiring PVC recreation.
- **Service restart is MANDATORY**: Existing NFS mounts cache the resolved IP and will NOT automatically reconnect after DNS update. Only newly created pods will use the new IP.
- **Complete restart required**: Partial restart causes "split-brain" state where some pods connect to old IP (unavailable) and some to new IP (working), causing application failures especially for CAS.
- **DNS TTL is 300 seconds (5 minutes)**. DNS propagation is typically fast. The main time factors during failover are: (1) Breaking replication, (2) Updating DNS record, and (3) Service restart to force remount.
- Replica volume is **read-only** during normal operations. After failover, you must break replication peering to make it read-write.
- **Validated behavior**: New compute-server pods successfully mounted from replica IP (192.168.3.5) after DNS update WITHOUT service restart. However, existing CAS pods remained connected to old IP (192.168.3.4), causing controller cycling until full service restart was performed.
- For Azure documentation, see: [Azure NetApp Files Cross-Zone Replication](https://learn.microsoft.com/en-us/azure/azure-netapp-files/create-cross-zone-replication)

### CZR Failback After Zone Recovery

When the primary zone recovers and you want to failback from replica to original primary:

> **⚠️ IMPORTANT**: Export policies must remain identical on both volumes. Verify before failback.

**Option 1: Simple DNS Flip (Quick Failback)**

Use this when data written to replica after failover is NOT critical and can be discarded.

```bash
# 1. Break replication on CURRENT primary (former replica)
az netappfiles volume replication remove \
  --resource-group <rg-name> \
  --account-name <account-name> \
  --pool-name <pool-name> \
  --volume-name <volume-name>-replica

# 2. Update DNS back to original primary IP
DNS_ZONE=$(terraform output -raw netapp_dns_hostname | cut -d. -f2-)
RECORD_NAME=$(terraform output -raw netapp_dns_hostname | cut -d. -f1)
ORIGINAL_PRIMARY_IP=$(terraform output -raw netapp_primary_ip | jq -r '.[0]')
RG_NAME="<your-resource-group>"

az network private-dns record-set a update \
  --resource-group $RG_NAME \
  --zone-name $DNS_ZONE \
  --name $RECORD_NAME \
  --set aRecords[0].ipv4Address=$ORIGINAL_PRIMARY_IP

# 3. Restart ALL Viya services (MANDATORY)
kubectl scale deployment --all --replicas=0 -n <viya-namespace>
kubectl scale statefulset --all --replicas=0 -n <viya-namespace>
kubectl wait --for=delete pod --all -n <viya-namespace> --timeout=600s
# Scale back up with original replica counts

# Data Loss: Changes made to replica after failover are LOST
```

**Option 2: Reverse Replication (No Data Loss)**

Use this when data written to replica after failover MUST be preserved.

```bash
# 1. Break replication on current primary (former replica)
az netappfiles volume replication remove \
  --resource-group <rg-name> \
  --account-name <account-name> \
  --pool-name <pool-name> \
  --volume-name <volume-name>-replica

# 2. Configure REVERSE replication (replica → original primary)
# This syncs data FROM replica (Zone 2) TO original primary (Zone 1)
az netappfiles volume replication approve \
  --resource-group <rg-name> \
  --account-name <account-name> \
  --pool-name <pool-name> \
  --volume-name <volume-name> \
  --remote-volume-resource-id "/subscriptions/.../volumes/<volume-name>-replica"

# 3. Wait for reverse replication to complete (may take hours depending on data)
az netappfiles volume replication status show \
  --resource-group <rg-name> \
  --account-name <account-name> \
  --pool-name <pool-name> \
  --volume-name <volume-name>
# Wait for Mirror State: "Mirrored"

# 4. Break reverse replication (makes original primary R/W)
az netappfiles volume replication remove \
  --resource-group <rg-name> \
  --account-name <account-name> \
  --pool-name <pool-name> \
  --volume-name <volume-name>

# 5. Update DNS back to original primary
# (Same as Option 1 Step 2)

# 6. Restart ALL Viya services
# (Same as Option 1 Step 3)

# 7. Re-establish original replication direction
# (primary → replica) via Terraform or Azure Portal

# Time Required: Varies based on data size for reverse replication
# Data Loss: None (all data preserved)
```

**Failback Decision Matrix:**

| Scenario | Data on Replica Critical? | Recommended Option | Data Loss |
|----------|---------------------------|-----------------------|----------|
| Short outage (< 1 hour) | No | Option 1 (DNS Flip) | Yes (replica changes lost) |
| Short outage (< 1 hour) | Yes | Option 2 (Reverse Replication) | No |
| Extended outage (> 1 day) | Yes (significant writes) | Option 2 (Reverse Replication) | No |
| Testing/DR drill | No | Option 1 (DNS Flip) | Yes (test data) |

**Post-Failback Validation:**
```bash
# Verify DNS points to original primary
nslookup nfs.sas-viya.internal
# Should resolve to original primary IP (e.g., 192.168.3.4)

# Verify pods mount from original primary
kubectl exec -it <pod-name> -n <viya-namespace> -- mount | grep nfs.sas-viya.internal
# Should show addr=<original-primary-ip>

# Verify all pods running
kubectl get pods -n <viya-namespace>
```

### NetApp Replication Behavior

When `netapp_enable_cross_zone_replication = true`:

| Aspect | Behavior |
| :--- | :--- |
| **Primary Volume** | Deployed in `netapp_availability_zone` |
| **Replica Volume** | Deployed in `netapp_replication_zone` |
| **Replication Type** | Asynchronous (near-real-time) |
| **Failover** | Manual (requires user action) |

### Validation

The configuration validates that:
- `netapp_availability_zone` is one of: `"1"`, `"2"`, `"3"`, or `null`
- `netapp_replication_zone` is one of: `"1"`, `"2"`, `"3"`, or `null`
- `netapp_replication_frequency` is one of: `"10minutes"`, `"hourly"`, `"daily"`
- When `netapp_enable_cross_zone_replication = true`: `netapp_replication_zone` must differ from `netapp_availability_zone`
- When `netapp_enable_cross_zone_replication = true`: `netapp_network_features` must be `"Standard"`

**Validation Failure Examples:**
```hcl
# ERROR 1: Same zones for replication
netapp_enable_cross_zone_replication = true
netapp_availability_zone             = "1"
netapp_replication_zone              = "1"  # ERROR: Must differ

# ERROR 2: Wrong network features for replication
netapp_enable_cross_zone_replication = true
netapp_network_features              = "Basic"  # ERROR: Must be "Standard"

# ERROR 3: Invalid replication frequency
netapp_replication_frequency = "every-5-minutes"  # ERROR: Invalid value
```

---

## NFS VM with Zone-Redundant Storage

For deployments using standard NFS server VM (`storage_type = "standard"`), you can deploy the NFS VM in a specific zone with zone-redundant storage (ZRS) disks.

### Configuration Variables

| Name | Description | Type | Default | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `nfs_vm_zone` | Zone in which NFS server VM should be created | string | `null` | Valid values: `"1"`, `"2"`, `"3"` |
| `nfs_raid_disk_type` | Managed disk type for RAID disks | string | `"Standard_LRS"` | Use `"StandardSSD_ZRS"` or `"Premium_ZRS"` for zone-redundant storage |
| `os_disk_storage_account_type` | OS disk type | string | `"StandardSSD_LRS"` | Use `"StandardSSD_ZRS"` or `"Premium_ZRS"` for zone-redundant storage |

### Usage Example

```hcl
# NFS VM with Zone-Redundant Storage
storage_type = "standard"

# Place NFS VM in Zone 1
nfs_vm_zone = "1"

# Use zone-redundant disks (survive zone failure)
nfs_raid_disk_type           = "StandardSSD_ZRS"
os_disk_storage_account_type = "StandardSSD_ZRS"

# NFS VM configuration
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_vm_machine_type  = "Standard_D4s_v5"
nfs_raid_disk_size   = 256
```

### NFS VM Limitations

⚠️ **IMPORTANT**: Zone-redundant disks provide data protection but **NOT VM-level high availability:

| Aspect | Behavior |
| :--- | :--- |
| **Data Protection** | ZRS disks replicate data across 3 zones ✅ |
| **VM Location** | VM remains in single zone (e.g., Zone 1) |
| **Zone Failure** | Data survives, but VM becomes unavailable |
| **Recovery** | VM does **NOT** auto-restart in another zone |
| **Manual Intervention** | Admin must recreate VM or use Azure Site Recovery |

**Comparison with NetApp CZR:**

```
NFS VM with ZRS:                    NetApp CZR:
- Data survives zone failure ✅    - Data survives zone failure ✅
- VM stuck in failed zone ❌       - Replica volume in different zone ✅
- VM won't auto-restart ❌         - Can access replica volume immediately ✅
- Requires VM recreation ❌        - Just update DNS + restart pods ✅
```

**Recommendation**: For production multi-AZ deployments, use **Azure NetApp Files with CZR** instead of NFS VM, even though it requires manual failover. The recovery time is significantly better (minutes vs hours).

---

## AKS Node Pool Zone Configuration

### Global Zone Configuration

Applies to all node pools unless overridden:

```hcl
# All node pools will span zones 1, 2, and 3
default_nodepool_availability_zones = ["1", "2", "3"]
node_pools_availability_zones       = ["1", "2", "3"]
```

### Per-Node-Pool Zone Configuration

You can specify zones individually for each node pool:

```hcl
node_pools = {
  cas = {
    "machine_type" = "Standard_E16ds_v5"
    "min_nodes"    = 3
    "max_nodes"    = 5
    "availability_zones" = ["1"]  # CAS only in Zone 1
  },
  compute = {
    "machine_type" = "Standard_D4ds_v5"
    "min_nodes"    = 3
    "max_nodes"    = 5
    "availability_zones" = ["1", "2", "3"]  # Compute across all zones
  },
  stateless = {
    "machine_type" = "Standard_D4s_v5"
    "min_nodes"    = 3
    "max_nodes"    = 6
    "availability_zones" = ["1", "2", "3"]  # Stateless across all zones
  },
  stateful = {
    "machine_type" = "Standard_D4s_v5"
    "min_nodes"    = 3
    "max_nodes"    = 5
    "availability_zones" = ["1", "2", "3"]  # Stateful across all zones
  }
}
```

**Use Cases:**

- **CAS in single zone**: When using ANF CZR with primary in Zone 1, keep CAS in Zone 1 for lowest latency
- **Compute across zones**: Distribute compute pods for resilience
- **Stateless across zones**: Maximum availability for web/API services
- **Stateful across zones**: Data services benefit from zone distribution

---

## Multi-AZ Deployment Scenarios

### Scenario 1: AKS Multi-Zone Only (No Storage HA)

**Configuration:**
```hcl
# Multi-zone AKS
default_nodepool_availability_zones = ["1", "2", "3"]
node_pools_availability_zones       = ["1", "2", "3"]

# Single-zone PostgreSQL (no HA)
postgres_servers = {
  default = {}
}

# Single-zone storage (NFS or NetApp without replication)
storage_type = "standard"
nfs_vm_zone  = "1"
```

**Protection Level:**
- ✅ AKS pods reschedule to other zones if one zone fails
- ❌ PostgreSQL single point of failure
- ❌ Storage single point of failure
- **Use Case**: Development/testing environments

---

### Scenario 2: Full Multi-AZ (PostgreSQL + NetApp CZR + AKS)

**Configuration:**
```hcl
# Multi-zone AKS
default_nodepool_availability_zones = ["1", "2", "3"]
node_pools_availability_zones       = ["1", "2", "3"]

# Zone-redundant PostgreSQL
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"
    availability_zone         = "1"
    standby_availability_zone = "2"
  }
}

# NetApp with Cross-Zone Replication
storage_type                         = "ha"
netapp_enable_cross_zone_replication = true
netapp_availability_zone             = "1"
netapp_replication_zone              = "2"
netapp_network_features              = "Standard"
```

**Protection Level:**
- ✅ AKS pods reschedule automatically
- ✅ PostgreSQL auto-failover
- ✅ Storage data protected (manual failover required)
- **Use Case**: Production deployments requiring high availability

---

### Scenario 3: PostgreSQL HA + NFS VM ZRS + AKS

**Configuration:**
```hcl
# Multi-zone AKS
default_nodepool_availability_zones = ["1", "2", "3"]
node_pools_availability_zones       = ["1", "2", "3"]

# Zone-redundant PostgreSQL
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"
    availability_zone         = "1"
    standby_availability_zone = "2"
  }
}

# NFS VM with ZRS disks
storage_type                     = "standard"
nfs_vm_zone                      = "1"
nfs_raid_disk_type               = "StandardSSD_ZRS"
os_disk_storage_account_type     = "StandardSSD_ZRS"
```

**Protection Level:**
- ✅ AKS pods reschedule automatically
- ✅ PostgreSQL auto-failover
- ⚠️ Storage data survives but VM stuck in failed zone (manual recovery required)
- **Use Case**: Budget-constrained production (lower cost than NetApp but weaker storage HA)

---

### Scenario Comparison

| Scenario | AKS HA | PostgreSQL HA | Storage HA | RTO (Zone Failure) | Cost | Use Case |
|----------|---------|---------------|------------|--------------------|---------|-----------|
| **1: AKS Only** | ✅ Auto | ❌ No | ❌ No | Hours | $ | Dev/Test |
| **2: Full Multi-AZ** | ✅ Auto | ✅ Auto | ⚠️ Manual | ~15 min | $$$ | Production |
| **3: PostgreSQL + NFS ZRS** | ✅ Auto | ✅ Auto | ⚠️ Manual (slow) | Hours | $$ | Budget Production |

**Recommendation**: Use **Scenario 2** (Full Multi-AZ) for production workloads requiring true high availability.

---

## Complete Multi-AZ Example

Here's a complete configuration for a fully zone-redundant deployment:

```hcl
# Basic Configuration
prefix   = "myenv"
location = "eastus"

# ========================================
# AKS - Multi-zone node pools
# ========================================
default_nodepool_availability_zones = ["1", "2", "3"]
node_pools_availability_zones       = ["1", "2", "3"]

# ========================================
# PostgreSQL - Zone-Redundant HA
# ========================================
postgres_servers = {
  default = {
    sku_name                     = "GP_Standard_D4s_v3"
    administrator_login          = "pgadmin"
    administrator_password       = "YourSecurePassword123!"
    
    # Multi-AZ HA Configuration
    high_availability_mode       = "ZoneRedundant"
    availability_zone            = "1"
    standby_availability_zone    = "2"
    
    # PostgreSQL Settings
    storage_mb                   = 32768
    backup_retention_days        = 7
    connectivity_method          = "Private"
  }
}

# ========================================
# Azure NetApp Files - Cross-Zone Replication
# ========================================
storage_type                         = "ha"
netapp_service_level                 = "Premium"
netapp_size_in_tb                    = 4

# Multi-AZ Replication Configuration
netapp_network_features              = "Standard"     # Required for CZR
netapp_availability_zone             = "1"
netapp_enable_cross_zone_replication = true
netapp_replication_zone              = "2"
netapp_replication_frequency         = "10minutes"

# ========================================
# Access Control
# ========================================
default_public_access_cidrs = ["YOUR.IP.ADDRESS/32"]
cluster_endpoint_public_access_cidrs = ["YOUR.IP.ADDRESS/32"]
postgres_public_access_cidrs = ["YOUR.IP.ADDRESS/32"]

# ========================================
# Tags
# ========================================
tags = {
  "environment" = "production"
  "multi-az"    = "enabled"
  "owner"       = "your-team"
}
```

---

## Validation Rules

### PostgreSQL Validation

The following rules are enforced at `terraform plan` time:

1. **Zone Value Validation**
   - `availability_zone` must be `"1"`, `"2"`, `"3"`, or `null`
   - `standby_availability_zone` must be `"1"`, `"2"`, `"3"`, or `null`

2. **Zone Redundancy Rule**
   - When `high_availability_mode = "ZoneRedundant"`:
     - `standby_availability_zone` **MUST** differ from `availability_zone`
     - Same zone values will cause validation error

3. **HA Mode Validation**
   - `high_availability_mode` must be `"ZoneRedundant"`, `"SameZone"`, or `null`

### NetApp Validation

The following rules are enforced at `terraform plan` time:

1. **Zone Value Validation**
   - `netapp_availability_zone` must be `"1"`, `"2"`, `"3"`, or `null`
   - `netapp_replication_zone` must be `"1"`, `"2"`, `"3"`, or `null`

2. **Zone Redundancy Rule**
   - When `netapp_enable_cross_zone_replication = true`:
     - `netapp_replication_zone` **MUST** differ from `netapp_availability_zone`
     - Same zone values will cause validation error

3. **Network Features Rule**
   - When `netapp_enable_cross_zone_replication = true`:
     - `netapp_network_features` **MUST** be `"Standard"`
     - `"Basic"` will cause validation error

4. **Replication Frequency Validation**
   - `netapp_replication_frequency` must be one of: `"10minutes"`, `"hourly"`, `"daily"`

---

## Zone Failure Scenarios

### Scenario 1: Zone 1 Failure (Primary Zone Down)

| Component | Configuration | Behavior |
| :--- | :--- | :--- |
| **PostgreSQL** | `availability_zone = "1"`, `high_availability_mode = "ZoneRedundant"` | Auto-failover to Zone 2 standby |
| **NetApp** | `netapp_availability_zone = "1"`, replication enabled | Primary volume unavailable; manual failover to Zone 2 replica needed |
| **AKS Nodes** | Zones 1, 2, 3 | Pods rescheduled to Zones 2 & 3 |

### Scenario 2: Complete Zone Loss

When an entire availability zone is lost:

1. **Immediate Impact:**
   - AKS nodes in failed zone are unavailable
   - Pods are rescheduled to remaining zones (Kubernetes auto-scaling)
   - PostgreSQL automatically fails over to standby

2. **Recovery Steps:**
   - Monitor PostgreSQL failover completion
   - Access NetApp replica data in backup zone (manual process)
   - AKS cluster continues running in remaining zones

3. **Data Status:**
  - PostgreSQL: No data loss (synchronous replication)
  - NetApp: Safe (last replication interval)
  - AKS Persistent Volumes: Depends on volume type

---

## Backward Compatibility

### Existing Deployments

All existing configurations continue to work without modification:

```hcl
# Old configuration (still works)
postgres_servers = {
  default = {
    sku_name              = "GP_Standard_D4s_v3"
    administrator_login   = "pgadmin"
    administrator_password = "YourPassword123!"
  }
}

# Result: Single-zone PostgreSQL (no HA enabled)
```

### Migration Path

To enable multi-AZ features on existing infrastructure:

1. **Step 1:** Add multi-AZ variables to your tfvars
2. **Step 2:** Run `terraform plan` to validate configuration
3. **Step 3:** Review changes (Azure will add standby resources)
4. **Step 4:** Run `terraform apply` to deploy HA resources

No existing resources are destroyed or recreated.

---

## Default Values

### PostgreSQL Defaults (Single-Zone, No HA)
```hcl
high_availability_mode    = null      # HA disabled
availability_zone         = "1"       # Primary zone
standby_availability_zone = "2"       # Unused when HA disabled
```

### NetApp Defaults (Single-Zone, No Replication)
```hcl
netapp_availability_zone             = "1"      # Primary zone
netapp_enable_cross_zone_replication = false    # Replication disabled
netapp_replication_zone              = "2"      # Unused when disabled
netapp_replication_frequency         = "10minutes"
netapp_network_features              = "Basic"  # Basic network features
```

---

## Cost Considerations

Enabling multi-AZ features increases Azure costs:

| Feature | Cost Impact |
| :--- | :--- |
| PostgreSQL ZoneRedundant HA | +100% (standby server costs) |
| NetApp Cross-Zone Replication | +100% (replica volume costs) |
| Standard Network Features | +25% vs Basic (required for NetApp CZR) |

**Recommendation:** Enable multi-AZ only for production workloads requiring high availability.

---

## NetApp Cross-Zone Replication Limitations

- **Important:** While NetApp cross-zone replication provides data protection, it does **NOT provide automatic high availability**. Manual intervention is required during zone failure scenarios.

## 1. Manual Failover Required

Azure NetApp Files cross-zone replication is **passive** and **read-only**. Unlike PostgreSQL which has automatic failover:

- **Primary zone failure**: Replica volume remains in **read-only mode**
- **No automatic failover**: Applications continue trying to reach failed primary
- **Manual break-replication required**: Administrator must break replication to make replica read-write
- **DNS-based recovery** (when CZR DNS is enabled): Update DNS A record instead of recreating PVCs

**With DNS-based failover (this IaC):**
```
Zone 1 (Primary) FAILS
  ↓
Replica in Zone 2 is available but READ-ONLY
  ↓
Manual Steps:
  1. Break replication peering (make replica R/W)
  2. Update DNS A record to replica IP
  3. Restart Viya services (force NFS remount)
  ↓
Applications reconnect to new primary → WORKS
```

**Without DNS** (legacy approach):
- Must delete and recreate 100+ PVCs
- Update StorageClass with new IP address
- RTO: Hours, high risk of errors

## 2. Recovery Time & Data Loss Considerations

**Failover Time Components:**
- Break replication peering (making replica read-write)
- Update DNS A record to point to replica IP
- Restart all Viya services (mandatory for NFS remount)

**Data Loss Risk:**
Data loss depends on replication frequency setting:
- `10minutes`: Data written since last replication may be lost
- `hourly`: Up to the last hour of data may be lost
- `daily`: Up to the last day of data may be lost

Choose replication frequency based on your data criticality and acceptable data loss tolerance.

## 3. Replica is Read-Only During Normal Operations

- Replica volume **cannot accept writes** while primary is operational
- Cannot balance load across zones (unlike PostgreSQL replicas)
- Replica serves **no operational purpose** during normal times
- Only becomes usable when primary fails

**Implications:**
```
Normal Operation:
  App Server 1 (Zone 1) → Writes to Primary (Zone 1)
  App Server 2 (Zone 2) → Still reads from Primary (Zone 1) Cross-zone traffic

During Zone 1 Failure:
  App Server 1 → Manual failover to Replica (Zone 2) Manual step
  App Server 2 → Can now read from Replica (Zone 2) 
```

## 4. Network Features Requirement & Cost

Cross-zone replication **requires Standard network features**:

```
Basic Network Features     Standard Network Features
├─ Lower cost             ├─ Higher cost
├─ Limited performance    ├─ Better performance
├─ No replication support ├─ Supports cross-zone replication
└─ Single zone only       └─ Multi-zone capable
```

**Cost Impact:**
- Standard network features cost more than Basic
- Two capacity pools required (primary + replica)
- Doubles NetApp storage infrastructure costs

## 5. Replication Direction is One-Way Only

```
Primary Volume (Zone 1)  ──Replication──→  Replica Volume (Zone 2)
     (Read/Write)                               (Read-Only)
     
Normal Operation:
  - Apps write to Primary only
  - Replica cannot accept writes
  - Unidirectional traffic

After Zone 1 Failure (Manual Failover):
  - Apps must manually switch to Replica
  - Cannot automatically failback to Primary once it recovers
  - Requires break/recreate replication for failback
```

## 6. Failback Complexity After Zone Recovery

When the primary zone recovers, failback requires **manual steps**:

```
Zone 1 Recovers
  ↓
Replica still in "replicating" state (one-way)
  ↓
Manual Steps Required:
  1. Break replication relationship
  2. Decide on data direction (primary or replica state?)
  3. Promote appropriate volume to primary
  4. Re-establish replication if needed
  5. Update applications
  ↓
Process takes hours/days, not automatic
```

## 7. Dual Capacity Pool Management Overhead

Cross-zone replication requires **two separate capacity pools**:

```
Primary Pool               Replica Pool
├─ Zone 1                 ├─ Zone 2
├─ Service Level: Premium ├─ Service Level: Premium (must match)
├─ Size: 4 TB             ├─ Size: 4 TB (must match)
├─ Cost: $X               ├─ Cost: $X
└─ Primary Volume         └─ Replica Volume

Total Cost = 2x capacity pool cost (not 1x)
```

**Operational Overhead:**
- Monitor two capacity pools instead of one
- Maintain sizing consistency across zones
- Plan capacity for both pools
- Double the NetApp infrastructure to manage

## 8. No Automatic Application Failover

Unlike database-level HA (PostgreSQL), NetApp replication doesn't handle:

- Automatic connection switching
- Automatic read-only to read-write promotion (requires breaking replication)
- Automatic application reconfiguration
- Automatic failback

**Manual intervention required:**
- Break replication peering
- Update DNS A record (when CZR DNS enabled) OR recreate PVCs (without DNS)
- **Mandatory** application restart (NFS client caches IP at mount time)

**DNS-based failover improvement** (this IaC):
- ✅ No PVC recreation needed
- ✅ No StorageClass updates needed
- ✅ No connection string changes needed
- ⚠️ Still requires service restart (NFS client behavior)

## 9. Network Latency During Cross-Zone Replication

Replication traffic crosses availability zones:

```
Zone 1 Primary → Cross-Zone Network → Zone 2 Replica
   ↑
   └─ Network latency: 1-5ms (typical)
   └─ Network bandwidth shared with app traffic
   └─ May impact primary zone performance during heavy writes
```

## 10. Terraform Destroy Blocked by Active Replication

Azure does not allow deletion of NetApp volumes with active replication peering:

- **Terraform destroy fails**: Cannot destroy infrastructure while replication is active
- **Pre-requisite**: Must break replication peering before running terraform destroy
- **Manual step required**: Use Azure Portal or CLI to break replication, wait for "Broken" status (1-3 minutes)
- **No automatic cleanup**: Terraform cannot automatically break replication during destroy operations

**Breaking replication before destroy:**
```bash
# Break replication on replica volume
az netappfiles volume replication remove \
  --resource-group <rg-name> \
  --account-name <account-name> \
  --pool-name <pool-name> \
  --volume-name <volume-name>-replica

# Wait for status "Broken" before terraform destroy
```

## NetApp vs PostgreSQL High Availability Comparison

| Aspect | PostgreSQL HA | NetApp Replication (with DNS) | NetApp Replication (without DNS) |
|--------|---------------|-------------------------------|----------------------------------|
| **Failover Type** | Automatic | Manual | Manual |
| **Data Loss** | Minimal (synchronous replication) | Based on replication frequency | Based on replication frequency |
| **Read Load Balancing** | Yes (read replicas) | No (read-only replica) | No (read-only replica) |
| **Automatic Failback** | Yes | No (requires manual steps) | No (requires manual steps) |
| **Cost** | Moderate | High (dual pools) | High (dual pools) |
| **Operational Complexity** | Low | Medium (DNS simplifies) | High (manual PVC recreation) |
| **Use Case** | Database HA | Data protection + simplified recovery | Data protection only |

## Recommended Architecture

For **true multi-AZ resilience**, use **both** together:

```
Zone 1                          Zone 2
├─ PostgreSQL Primary (RW)      ├─ PostgreSQL Standby (RO)
├─ NetApp Primary (RW)          ├─ NetApp Replica (RO)
├─ AKS Nodes (Apps)             ├─ AKS Nodes (Apps)
└─ Auto-failover               └─ Auto-failover
   (Database)                      (Database)

Zone 1 Failure:
  PostgreSQL: Auto-failover to Zone 2 standby
  NetApp: Manual failover to Zone 2 replica (requires app config change)
  AKS: Kubernetes reschedules pods to Zone 2/3 nodes (automatic)
```

## Best Practices for NetApp Multi-AZ

1. **Use NetApp for compliance/backup**, not primary HA
2. **Rely on PostgreSQL automatic failover** for database HA
3. **Keep replication frequency at `10minutes`** for best balance of data protection and performance
4. **Monitor replication status** continuously using:
   ```bash
   # Check replication status
   az netappfiles volume replication status show \
     --resource-group <rg-name> \
     --account-name <account-name> \
     --pool-name <pool-name> \
     --volume-name <volume-name>-replica
   
   # Key metrics to monitor:
   # - Mirror State: Should be "Mirrored" during normal operations
   # - Mirror State: "Broken" after failover
   # - Health Status: Should be "Healthy"
   # - Lag Time: Should be < replication frequency (e.g., < 10 minutes)
   
   # Set up alerts for:
   # - Mirror State != "Mirrored" (indicates replication issue)
   # - Lag Time > 2x replication frequency (indicates sync lag)
   # - Health Status != "Healthy" (indicates errors)
   ```
5. **Document manual failover procedures** for NetApp
6. **Test failover scenarios** regularly (not just database)
7. **Have runbooks for**:
   - Zone failure detection
   - VNet peering recovery
   - Application failover to replica
   - Failback after zone recovery (Option 1 vs Option 2 decision)

## Limitations Summary

| Limitation | Severity | Mitigation |
|-----------|----------|-----------|
| Manual failover required | **Medium** | DNS-based failover simplifies procedure; documented recovery steps |
| Read-only replica | **Medium** | Cannot load-balance across zones; use for DR only |
| Break replication required | **High** | Manual step required; documented in recovery procedure |
| Dual pool cost | **Medium** | Budget for 2x NetApp cost; weigh against downtime cost |
| One-way replication | **Medium** | Plan failback procedure beforehand; two options documented |
| Failback complexity | **High** | Choose between quick DNS flip (data loss) or reverse replication (no data loss) |
| Mandatory service restart | **High** | NFS client behavior; unavoidable; plan for downtime during failover |
| Terraform destroy blocked | **Low** | Simple workaround: break replication first, then destroy; documented |

## References

### Azure Documentation
- [PostgreSQL Flexible Server High Availability](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-high-availability)
- [Azure NetApp Files Reliability](https://learn.microsoft.com/en-us/azure/reliability/reliability-netapp-files)
- [NetApp Cross-Zone Replication](https://learn.microsoft.com/en-us/azure/azure-netapp-files/create-cross-zone-replication)
- [Azure Availability Zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)
- [NetApp SnapMirror Replication](https://learn.microsoft.com/en-us/azure/azure-netapp-files/snapshots-restore-new-volume)
- [Azure High Availability Patterns](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/data/managed-postgres-ha)

### Related Configuration Files
- [CONFIG-VARS.md](CONFIG-VARS.md) - All configuration variables
- [examples/sample-input-multizone-enhanced.tfvars](../examples/sample-input-multizone-enhanced.tfvars) - Complete example configuration
