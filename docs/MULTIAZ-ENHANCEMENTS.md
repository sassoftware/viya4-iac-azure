# Multi-AZ Enhancement Summary

This directory contains enhanced versions of the IaC files with **true multi-AZ resilience** for Azure.

## Issues Addressed

These enhancements directly address the concerns raised in PSCLOUD-382 and related feedback:

### ✅ Issue 1: PostgreSQL Single-Zone Limitation
**Original Problem:** External PostgreSQL was provisioned in a single zone without HA capability, making it vulnerable to zone failures.

**Solution Implemented:**
- Added support for Azure PostgreSQL Flexible Server zone-redundant high availability
- Automatic failover between availability zones
- Minimal downtime (< 2 minutes) and no data loss during zone failures
- Comprehensive validations to prevent misconfiguration

### ✅ Issue 2: NetApp Single-Zone Limitation  
**Original Problem:** NetApp volumes were limited to single-zone deployment, creating a storage single point of failure.

**Solution Implemented:**
- Added support for Azure NetApp Files cross-zone replication
- Data survives zone failures with near-real-time replication
- Configurable replication frequency (10 minutes, hourly, daily)
- Validations ensure proper zone separation and network features

### ✅ Issue 3: Configuration Safety
**Original Problem:** Users could accidentally misconfigure multi-AZ settings, defeating the purpose of redundancy.

**Solution Implemented:**
- Comprehensive Terraform validations at variable level
- Runtime validation with descriptive error messages
- Fails fast at `terraform plan` stage (before deployment)
- Clear guidance on required configurations

## Files Created

### Main Configuration
- **`variables-multiaz.tf`** - Enhanced root variables file
  - Adds PostgreSQL HA variables (high_availability_mode, availability_zone, standby_availability_zone)
  - Adds NetApp cross-zone replication variables
  - Compare with: `variables.tf`

### Module Files

#### PostgreSQL Module
- **`modules/azurerm_postgresql_flex/main-multiaz.tf`** - Enhanced PostgreSQL configuration
  - Adds `zone` parameter for primary server placement
  - Adds `high_availability` block for zone-redundant HA
  - Compare with: `modules/azurerm_postgresql_flex/main.tf`

- **`modules/azurerm_postgresql_flex/variables-multiaz.tf`** - Enhanced PostgreSQL variables
  - Adds availability_zone, high_availability_mode, standby_availability_zone
  - Compare with: `modules/azurerm_postgresql_flex/variables.tf`

#### NetApp Module
- **`modules/azurerm_netapp/main-multiaz.tf`** - Enhanced NetApp configuration
  - Adds zone parameter to primary volume
  - Adds replica volume resource for cross-zone replication
  - Compare with: `modules/azurerm_netapp/main.tf`

- **`modules/azurerm_netapp/variables-multiaz.tf`** - Enhanced NetApp variables
  - Adds netapp_availability_zone, netapp_enable_cross_zone_replication
  - Adds netapp_replication_zone, netapp_replication_frequency
  - Compare with: `modules/azurerm_netapp/variables.tf`

### Example Configuration
- **`examples/sample-input-multizone-enhanced.tfvars`** - Complete example configuration
  - Shows PostgreSQL zone-redundant HA setup
  - Shows NetApp cross-zone replication setup
  - Documents zone failure scenarios
  - Compare with: `examples/sample-input-multizone.tfvars`

## Key Enhancements

### 1. PostgreSQL Multi-AZ HA
```hcl
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"  # Automatic failover
    availability_zone         = "1"               # Primary zone
    standby_availability_zone = "2"               # Standby zone
  }
}
```

**Benefits:**
- ✅ Automatic failover if primary zone fails
- ✅ No data loss
- ✅ Minimal downtime (typically < 2 minutes)
- ✅ Synchronous replication

### 2. NetApp Cross-Zone Replication
```hcl
storage_type                         = "ha"
netapp_availability_zone             = "1"
netapp_enable_cross_zone_replication = true
netapp_replication_zone              = "2"
netapp_replication_frequency         = "10minutes"
netapp_network_features              = "Standard"  # Required for CZR
```

**Benefits:**
- ✅ Data survives zone failure
- ✅ Near-real-time replication (10-minute intervals)
- ⚠️ Manual failover required (not automatic)
- ✅ No data loss (RPO = replication frequency)

### 3. NFS with Zone-Redundant Storage (Limited)
```hcl
storage_type                     = "standard"
nfs_raid_disk_type               = "StandardSSD_ZRS"
os_disk_storage_account_type     = "StandardSSD_ZRS"
nfs_vm_zone                      = "1"
```

**Limitations:**
- ⚠️ Disks survive zone failure but VM doesn't
- ⚠️ VM won't automatically restart in another zone
- ⚠️ Requires Azure Site Recovery or manual intervention
- ⚠️ **Not recommended for production multi-AZ deployments**

## Zone Failure Scenario

**If Zone 1 fails:**

| Component | Behavior |
|-----------|----------|
| **PostgreSQL** | ✅ Auto-fails to Zone 2 standby (< 2 min downtime) |
| **NetApp** | ✅ Data safe in Zone 2 replica (manual failover needed) |
| **Standard NFS** | ⚠️ Unavailable until zone recovers or manual DR |
| **AKS Nodes** | ✅ Continue in Zones 2 & 3, pods rescheduled |

## Comparison with Original

### Original Configuration Issues
1. ❌ PostgreSQL in single zone (no HA)
2. ❌ NetApp volume in single zone (no replication)
3. ❌ NFS VM in single zone (single point of failure)

### Enhanced Configuration
1. ✅ PostgreSQL with zone-redundant HA
2. ✅ NetApp with cross-zone replication
3. ⚠️ NFS still limited (use NetApp for production)

## Backward Compatibility

✅ **All enhancements are backward compatible**

### Existing Deployments Continue to Work:
- All new parameters have safe defaults
- PostgreSQL HA is **disabled by default** (`high_availability_mode = null`)
- NetApp cross-zone replication is **disabled by default** (`netapp_enable_cross_zone_replication = false`)
- Existing tfvars files work without modification
- Single-zone deployments remain the default behavior

### Migration Path:
1. **Current State**: Existing single-zone deployments continue working
2. **Optional Upgrade**: Add HA/replication parameters when ready
3. **Validation Protection**: Misconfigurations are caught before deployment
4. **Progressive Enhancement**: Enable features as needed without breaking existing infrastructure

## How to Use

1. **Compare files** - Use a diff tool to see changes:
   ```powershell
   code --diff variables.tf variables-multiaz.tf
   code --diff modules/azurerm_postgresql_flex/main.tf modules/azurerm_postgresql_flex/main-multiaz.tf
   code --diff modules/azurerm_netapp/main.tf modules/azurerm_netapp/main-multiaz.tf
   ```

2. **Review changes** - Understand what each enhancement does

3. **Test configuration** - Use the enhanced tfvars:
   ```powershell
   terraform plan -var-file=examples/sample-input-multizone-enhanced.tfvars
   ```

4. **Validate** - Terraform will catch any configuration errors during plan:
   ```powershell
   terraform plan  # Validations run here
   ```

5. **Merge changes** - Carefully integrate enhancements into your main files

## Important Notes

### Validations Added
The enhanced files include comprehensive validations to prevent misconfigurations:

#### PostgreSQL Validations:
- ✅ **Zone Conflict Prevention**: When `high_availability_mode = "ZoneRedundant"`, the validation ensures `standby_availability_zone` differs from `availability_zone`
- ✅ **Early Error Detection**: Terraform will fail at `plan` stage with clear error messages if zones are misconfigured
- ✅ **Safe Defaults**: All new parameters have defaults that maintain backward compatibility

#### NetApp Validations:
- ✅ **Network Features Requirement**: When `netapp_enable_cross_zone_replication = true`, validation enforces `network_features = "Standard"`
- ✅ **Zone Conflict Prevention**: Ensures `netapp_replication_zone` differs from `netapp_availability_zone` when replication is enabled
- ✅ **Replication Frequency**: Validates frequency is one of: `10minutes`, `hourly`, or `daily`

### Configuration Requirements

- **Network Features**: Cross-zone NetApp replication requires `netapp_network_features = "Standard"`
- **Zone Selection**: standby_availability_zone MUST differ from availability_zone for ZoneRedundant mode (enforced by validation)
- **Zone Selection**: netapp_replication_zone MUST differ from netapp_availability_zone when replication is enabled (enforced by validation)
- **Cost Impact**: HA features increase costs (standby servers, replica storage)
- **Testing**: Always test failover procedures before production use

### Validation Examples

**Valid Configuration:**
```hcl
# PostgreSQL - Zones differ ✅
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"
    availability_zone         = "1"
    standby_availability_zone = "2"  # Different from primary
  }
}

# NetApp - Zones differ ✅
netapp_availability_zone             = "1"
netapp_enable_cross_zone_replication = true
netapp_replication_zone              = "2"  # Different from primary
netapp_network_features              = "Standard"  # Required for replication
```

**Invalid Configuration (Will Fail at terraform plan):**
```hcl
# ❌ ERROR: Same zones for PostgreSQL ZoneRedundant HA
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"
    availability_zone         = "1"
    standby_availability_zone = "1"  # ❌ Same as primary - VALIDATION ERROR
  }
}

# ❌ ERROR: Same zones for NetApp cross-zone replication
netapp_availability_zone             = "1"
netapp_enable_cross_zone_replication = true
netapp_replication_zone              = "1"  # ❌ Same as primary - VALIDATION ERROR

# ❌ ERROR: Cross-zone replication without Standard network features
netapp_enable_cross_zone_replication = true
netapp_network_features              = "Basic"  # ❌ Must be "Standard" - VALIDATION ERROR
```

## References

- [Azure NetApp Files Multi-Zone](https://learn.microsoft.com/en-us/azure/reliability/reliability-netapp-files)
- [NetApp Cross-Zone Replication](https://learn.microsoft.com/en-us/azure/azure-netapp-files/create-cross-zone-replication)
- [PostgreSQL Flexible Server HA](https://docs.azure.cn/en-us/postgresql/flexible-server/overview#architecture-and-high-availability)
- [Azure Availability Zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview)
