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

## References

### Azure Documentation
- [PostgreSQL Flexible Server High Availability](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-high-availability)
- [Azure NetApp Files Reliability](https://learn.microsoft.com/en-us/azure/reliability/reliability-netapp-files)
- [NetApp Cross-Zone Replication](https://learn.microsoft.com/en-us/azure/azure-netapp-files/create-cross-zone-replication)
- [Azure Availability Zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)

### Related Configuration Files
- [CONFIG-VARS.md](CONFIG-VARS.md) - All configuration variables
- [examples/sample-input-multizone-enhanced.tfvars](../examples/sample-input-multizone-enhanced.tfvars) - Complete example configuration

---

## Troubleshooting

### Validation Error: Zone Mismatch

**Error:**
```
Error: Invalid value for variable

When high_availability_mode is 'ZoneRedundant', standby_availability_zone 
must differ from availability_zone...
```

**Solution:** Ensure `standby_availability_zone` ≠ `availability_zone`

### Validation Error: Network Features

**Error:**
```
Error: Invalid value for variable

When netapp_enable_cross_zone_replication is enabled, network_features 
must be set to 'Standard'...
```

**Solution:** Set `netapp_network_features = "Standard"` when enabling replication

### Validation Error: Invalid Zone Value

**Error:**
```
Error: Invalid value for variable

NetApp availability zone must be '1', '2', '3', or null.
```

**Solution:** Use only `"1"`, `"2"`, `"3"`, or `null` for zone values

---

## Support

For issues or questions:
- Check [CONFIG-VARS.md](CONFIG-VARS.md) for general variable documentation
- Review [examples/sample-input-multizone-enhanced.tfvars](../examples/sample-input-multizone-enhanced.tfvars) for complete examples
- Run `terraform validate` to check configuration syntax
- Run `terraform plan` to validate all rules before deploying
