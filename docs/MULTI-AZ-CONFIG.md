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
  - [NetApp Cross-Zone Replication Limitations](#netapp-cross-zone-replication-limitations)
    - [1. Manual Failover Required](#1-manual-failover-required)
    - [2. Recovery Time & Data Loss Objectives](#2-recovery-time--data-loss-objectives)
    - [3. Replica is Read-Only During Normal Operations](#3-replica-is-read-only-during-normal-operations)
    - [4. Network Features Requirement & Cost](#4-network-features-requirement--cost)
    - [5. Manual Break-Peering During Zone Failures](#5-manual-break-peering-during-zone-failures)
    - [6. Replication Direction is One-Way Only](#6-replication-direction-is-one-way-only)
    - [7. Failback Complexity After Zone Recovery](#7-failback-complexity-after-zone-recovery)
    - [8. Dual Capacity Pool Management Overhead](#8-dual-capacity-pool-management-overhead)
    - [9. No Automatic Application Failover](#9-no-automatic-application-failover)
    - [10. Network Latency During Cross-Zone Replication](#10-network-latency-during-cross-zone-replication)
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
| **Failover** | Automatic (typically < 60 seconds) |
| **RPO** | ~0 seconds (synchronous) |
| **RTO** | < 60 seconds (automatic failover) |

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

Enable cross-zone replication for Azure NetApp Files storage. Data is replicated to a volume in a different availability zone for disaster recovery.

### Configuration Variables

| Name | Description | Type | Default | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `netapp_availability_zone` | Primary volume availability zone | string | `"1"` | Valid values: `"1"`, `"2"`, `"3"` |
| `netapp_enable_cross_zone_replication` | Enable cross-zone replication | bool | `false` | Requires `netapp_network_features = "Standard"` |
| `netapp_replication_zone` | Replica volume availability zone | string | `"2"` | **Must differ from `netapp_availability_zone`** |
| `netapp_replication_frequency` | Replication frequency | string | `"10minutes"` | Options: `"10minutes"`, `"hourly"`, `"daily"` |
| `netapp_network_features` | Network features required for replication | string | `"Basic"` | Must be `"Standard"` when replication is enabled |

### Usage Example

```hcl
# Enable NetApp Cross-Zone Replication
storage_type                         = "ha"
netapp_service_level                 = "Premium"
netapp_size_in_tb                    = 4
netapp_network_features              = "Standard"     # Required for cross-zone replication

# Multi-AZ Configuration
netapp_availability_zone             = "1"            # Primary volume in zone 1
netapp_enable_cross_zone_replication = true
netapp_replication_zone              = "2"            # Replica in zone 2
netapp_replication_frequency         = "10minutes"    # Replicate every 10 minutes
```

### NetApp Replication Behavior

When `netapp_enable_cross_zone_replication = true`:

| Aspect | Behavior |
| :--- | :--- |
| **Primary Volume** | Deployed in `netapp_availability_zone` |
| **Replica Volume** | Deployed in `netapp_replication_zone` |
| **Replication Type** | Asynchronous (near-real-time) |
| **Failover** | Manual (requires user action) |
| **RPO** | Based on replication frequency (10 min to daily) |
| **RTO** | 5-15 minutes (manual failover) |

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
| **PostgreSQL** | `availability_zone = "1"`, `high_availability_mode = "ZoneRedundant"` | Auto-failover to Zone 2 standby (< 60 sec) |
| **NetApp** | `netapp_availability_zone = "1"`, replication enabled | Primary volume unavailable; manual failover to Zone 2 replica needed |
| **AKS Nodes** | Zones 1, 2, 3 | Pods rescheduled to Zones 2 & 3 |

### Scenario 2: Complete Zone Loss

When an entire availability zone is lost:

1. **Immediate Impact:**
   - AKS nodes in failed zone are unavailable
   - Pods are rescheduled to remaining zones (Kubernetes auto-scaling)
   - PostgreSQL automatically fails over to standby

2. **Recovery Steps:**
   - Monitor PostgreSQL failover completion (typically < 60 seconds)
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
- **Manual switching required**: Applications must be manually reconfigured to use replica
- **No automatic DNS updates**: Connection strings must be manually updated

**Example scenario:**
```
Zone 1 (Primary) FAILS
  ↓
Replica in Zone 2 is available but READ-ONLY
  ↓
Applications still trying to reach Zone 1 → FAIL
  ↓
Manual intervention: Update app config to Zone 2 → Works (read-only)
```

## 2. Recovery Time & Data Loss Objectives

| Metric | Value | Notes |
|--------|-------|-------|
| **RTO (Recovery Time Objective)** | Manual | Depends on how quickly you can redirect traffic |
| **RPO (Recovery Point Objective)** | Configurable | Based on replication frequency setting |

**RPO by Replication Frequency:**
- `10minutes`: Up to 10 minutes of data loss possible
- `hourly`: Up to 1 hour of data loss possible
- `daily`: Up to 24 hours of data loss possible

**Example with 10-minute replication:**
```
14:00 - Data written to primary
14:05 - Replication sync to replica
14:10 - Primary fails
        → Data written between 14:05-14:10 may be lost
        → RPO = 5 minutes of potential data loss
```

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

## 5. Manual Break-Peering During Zone Failures

**Critical Limitation**: If your deployment uses VNet peering with BYO (Bring Your Own) networks:

During zone failure:
1. Primary zone fails
2. Replica becomes read-only in different zone
3. VNet peering connections may require **manual verification/re-establishment**
4. Applications may lose connectivity to replica even if it's available

**Required Manual Steps:**
```
Zone Failure Detected
  ↓
Verify VNet peering status
  ↓
If peering broken:
  ├─ Break existing peering (if needed)
  ├─ Re-establish new peering relationship
  └─ Verify connectivity restored
  ↓
Switch application to replica volume
  ↓
Update DNS/connection strings
  ↓
Service restored (manual process = hours not minutes)
```

**References:**
- [Azure VNet Peering Troubleshooting](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-troubleshoot-peering-issues)
- [Peering Best Practices](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview#best-practices)

## 6. Replication Direction is One-Way Only

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

## 7. Failback Complexity After Zone Recovery

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

## 8. Dual Capacity Pool Management Overhead

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

## 9. No Automatic Application Failover

Unlike database-level HA (PostgreSQL), NetApp replication doesn't handle:

- Automatic connection switching
- Automatic DNS updates
- Automatic read-only to read-write promotion
- Automatic application reconfiguration
- Automatic failback

**All require manual intervention** through:
- Application reconfiguration
- Kubernetes persistent volume updates
- Connection string changes
- Possible application restart

## 10. Network Latency During Cross-Zone Replication

Replication traffic crosses availability zones:

```
Zone 1 Primary → Cross-Zone Network → Zone 2 Replica
   ↑
   └─ Network latency: 1-5ms (typical)
   └─ Network bandwidth shared with app traffic
   └─ May impact primary zone performance during heavy writes
```

## NetApp vs PostgreSQL High Availability Comparison

| Aspect | PostgreSQL HA | NetApp Replication |
|--------|---------------|-------------------|
| **Failover Type** | Automatic | Manual |
| **RTO** | < 60 seconds | Hours/Days (manual) |
| **RPO** | < 30 seconds | Configurable (10min-daily) |
| **Read Load Balancing** | Yes (read replicas) | No (read-only replica) |
| **Automatic Failback** | Yes | No (requires manual steps) |
| **Cost** | Moderate | High (dual pools) |
| **Operational Complexity** | Low | High |
| **Use Case** | Database HA | Data protection only |

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
  PostgreSQL: Auto-failover to Zone 2 standby (60s)
  NetApp: Manual failover to Zone 2 replica (requires app config change)
  AKS: Kubernetes reschedules pods to Zone 2/3 nodes (automatic)
```

## Best Practices for NetApp Multi-AZ

1. **Use NetApp for compliance/backup**, not primary HA
2. **Rely on PostgreSQL automatic failover** for database HA
3. **Keep replication frequency at `10minutes`** for RTO/RPO balance
4. **Monitor replication status** continuously
5. **Document manual failover procedures** for NetApp
6. **Test failover scenarios** regularly (not just database)
7. **Have runbooks for**:
   - Zone failure detection
   - VNet peering recovery
   - Application failover to replica
   - Failback after zone recovery

## Limitations Summary

| Limitation | Severity | Mitigation |
|-----------|----------|-----------|
| Manual failover required | **High** | Rely on PostgreSQL HA for DB failover |
| RTO/RPO constraints | **High** | Use 10min replication frequency |
| Read-only replica | **Medium** | Cannot load-balance across zones |
| VNet peering manual fix | **High** | Document procedures; monitor peering |
| Dual pool cost | **Medium** | Budget for 2x NetApp cost |
| One-way replication | **Medium** | Plan failback procedure beforehand |
| Failback complexity | **High** | Have documented runbooks |
| No automatic failover | **High** | Combine with PostgreSQL HA |

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
