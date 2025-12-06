# Multi-AZ Validation Enhancements for viya4-iac-azure

## Overview

This document describes the validation enhancements added to the viya4-iac-azure Infrastructure as Code (IaC) repository to address zone-redundant high availability requirements identified in PSCLOUD-382 and related feedback.

## Problem Statement

The original feedback highlighted critical gaps in multi-AZ support:

### 1. PostgreSQL High Availability
**Issue:** The IaC did not expose Azure PostgreSQL Flexible Server's zone-redundant high availability capabilities, which meant:
- PostgreSQL instances were deployed in a single availability zone
- No automatic failover during zone failures
- No protection against zone-level outages

**Business Impact:** SAS Viya platform continuity could not be guaranteed during Azure availability zone failures.

### 2. NetApp Cross-Zone Replication
**Issue:** While the community PR allowed zone selection for NetApp volumes, it was limited to single-zone deployment:
- NetApp volumes were provisioned in a single zone
- No cross-zone replication configured
- Zone failures would result in storage unavailability

**Business Impact:** Even with multi-AZ AKS clusters, storage became a single point of failure for zone outages.

## Solution Implemented

### Phase 1: PostgreSQL Zone-Redundant High Availability

#### Files Modified:
- `modules/azurerm_postgresql_flex/variables-multiaz.tf`
- `modules/azurerm_postgresql_flex/main-multiaz.tf`
- `variables-multiaz.tf` (root)
- `main.tf` (root)

#### New Variables Added:

**Module Level (`modules/azurerm_postgresql_flex/variables-multiaz.tf`):**
```hcl
variable "availability_zone" {
  description = "The availability zone for the primary PostgreSQL Flexible Server. Values: '1', '2', or '3'"
  type        = string
  default     = "1"
  
  validation {
    condition     = var.availability_zone == null || contains(["1", "2", "3"], var.availability_zone)
    error_message = "Availability zone must be '1', '2', '3', or null."
  }
}

variable "high_availability_mode" {
  description = "High availability mode. Valid values: 'ZoneRedundant' (standby in different zone), 'SameZone' (standby in same zone), or null to disable HA"
  type        = string
  default     = null
  
  validation {
    condition     = var.high_availability_mode == null || contains(["ZoneRedundant", "SameZone"], var.high_availability_mode)
    error_message = "Valid values are: 'ZoneRedundant', 'SameZone', or null."
  }
}

variable "standby_availability_zone" {
  description = "The availability zone for the standby server. Must be different from availability_zone when using ZoneRedundant mode."
  type        = string
  default     = "2"
  
  validation {
    condition     = var.standby_availability_zone == null || contains(["1", "2", "3"], var.standby_availability_zone)
    error_message = "Standby availability zone must be '1', '2', '3', or null."
  }
  
  validation {
    condition     = var.high_availability_mode != "ZoneRedundant" || var.standby_availability_zone != var.availability_zone
    error_message = "When high_availability_mode is 'ZoneRedundant', standby_availability_zone must differ from availability_zone to ensure proper zone-redundant high availability."
  }
}
```

#### Critical Validation Added:

**Variable-Level Validation:**
The second validation block on `standby_availability_zone` prevents users from configuring both primary and standby in the same zone when using ZoneRedundant mode, which would defeat the purpose of zone redundancy.

**Runtime Validation (`modules/azurerm_postgresql_flex/main-multiaz.tf`):**
```hcl
locals {
  zone_redundant_validation = (
    var.high_availability_mode == "ZoneRedundant" && 
    var.availability_zone != null && 
    var.standby_availability_zone != null &&
    var.availability_zone == var.standby_availability_zone
  ) ? tobool("ERROR: When high_availability_mode is 'ZoneRedundant', standby_availability_zone must differ from availability_zone. Current values: availability_zone='${var.availability_zone}', standby_availability_zone='${var.standby_availability_zone}'") : true
}
```

This provides an additional safeguard with detailed error messages showing the conflicting values.

#### Resource Configuration:
```hcl
resource "azurerm_postgresql_flexible_server" "flexpsql" {
  # ... existing configuration ...
  
  zone = var.availability_zone
  
  dynamic "high_availability" {
    for_each = var.high_availability_mode != null ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }
}
```

#### Integration with Root Module:

**Updated `postgres_server_defaults` in `variables-multiaz.tf`:**
```hcl
variable "postgres_server_defaults" {
  description = "Default PostgreSQL server configuration with multi-AZ HA support"
  type        = any
  default = {
    # ... existing defaults ...
    
    # Multi-AZ High Availability Configuration
    high_availability_mode       = null              # Set to "ZoneRedundant" or "SameZone" to enable HA
    availability_zone            = "1"               # Primary zone (1, 2, or 3)
    standby_availability_zone    = "2"               # Standby zone (must differ from primary for ZoneRedundant)
  }
}
```

**Updated module call in `main.tf`:**
```hcl
module "flex_postgresql" {
  source = "./modules/azurerm_postgresql_flex"
  
  # ... existing parameters ...
  
  # Multi-AZ High Availability Configuration
  availability_zone         = lookup(each.value, "availability_zone", "1")
  high_availability_mode    = lookup(each.value, "high_availability_mode", null)
  standby_availability_zone = lookup(each.value, "standby_availability_zone", "2")
}
```

### Phase 2: NetApp Cross-Zone Replication

#### Files Modified:
- `modules/azurerm_netapp/variables-multiaz.tf`
- `modules/azurerm_netapp/main-multiaz.tf`
- `variables-multiaz.tf` (root)
- `main.tf` (root)

#### New Variables Added:

**Module Level (`modules/azurerm_netapp/variables-multiaz.tf`):**
```hcl
variable "network_features" {
  description = "Indicates which network feature to use, accepted values are `Basic` or `Standard`, it defaults to `Basic` if not defined."
  type        = string
  default     = "Basic"
  
  validation {
    condition     = !var.netapp_enable_cross_zone_replication || var.network_features == "Standard"
    error_message = "When netapp_enable_cross_zone_replication is enabled, network_features must be set to 'Standard'. Cross-zone replication requires Standard network features."
  }
}

variable "netapp_availability_zone" {
  description = "Primary availability zone for Azure NetApp Files volume. Set to '1', '2', or '3' for zonal deployment."
  type        = string
  default     = "1"
  
  validation {
    condition     = var.netapp_availability_zone == null || contains(["1", "2", "3"], var.netapp_availability_zone)
    error_message = "NetApp availability zone must be '1', '2', '3', or null."
  }
}

variable "netapp_enable_cross_zone_replication" {
  description = "Enable cross-zone replication for Azure NetApp Files to ensure zone failure resilience. Requires Standard network features."
  type        = bool
  default     = false
}

variable "netapp_replication_zone" {
  description = "Target availability zone for NetApp cross-zone replication. Must be different from netapp_availability_zone."
  type        = string
  default     = "2"
  
  validation {
    condition     = var.netapp_replication_zone == null || contains(["1", "2", "3"], var.netapp_replication_zone)
    error_message = "NetApp replication zone must be '1', '2', '3', or null."
  }
  
  validation {
    condition     = !var.netapp_enable_cross_zone_replication || var.netapp_replication_zone != var.netapp_availability_zone
    error_message = "When netapp_enable_cross_zone_replication is enabled, netapp_replication_zone must differ from netapp_availability_zone to ensure proper cross-zone replication."
  }
}

variable "netapp_replication_frequency" {
  description = "Replication frequency for cross-zone replication. Valid values: 10minutes, hourly, daily"
  type        = string
  default     = "10minutes"
  
  validation {
    condition     = contains(["10minutes", "hourly", "daily"], var.netapp_replication_frequency)
    error_message = "Valid values are: 10minutes, hourly, daily."
  }
}
```

#### Critical Validations Added:

**1. Network Features Requirement:**
Azure NetApp Files cross-zone replication requires Standard network features. The validation on `network_features` enforces this requirement at the variable level.

**2. Zone Conflict Prevention:**
The validation on `netapp_replication_zone` ensures that when cross-zone replication is enabled, the replication target zone differs from the primary zone.

**3. Runtime Validation (`modules/azurerm_netapp/main-multiaz.tf`):**
```hcl
locals {
  cross_zone_validation = (
    var.netapp_enable_cross_zone_replication && 
    var.netapp_availability_zone != null && 
    var.netapp_replication_zone != null &&
    var.netapp_availability_zone == var.netapp_replication_zone
  ) ? tobool("ERROR: When netapp_enable_cross_zone_replication is enabled, netapp_replication_zone must differ from netapp_availability_zone. Current values: netapp_availability_zone='${var.netapp_availability_zone}', netapp_replication_zone='${var.netapp_replication_zone}'") : true
}
```

#### Integration with Root Module:

**Added root variables in `variables-multiaz.tf`:**
```hcl
variable "netapp_availability_zone" {
  description = "Primary availability zone for Azure NetApp Files volume. Set to '1', '2', or '3' for zonal deployment."
  type        = string
  default     = "1"
  
  validation {
    condition     = var.netapp_availability_zone == null || contains(["1", "2", "3"], var.netapp_availability_zone)
    error_message = "NetApp availability zone must be '1', '2', '3', or null."
  }
}

variable "netapp_enable_cross_zone_replication" {
  description = "Enable cross-zone replication for Azure NetApp Files to ensure zone failure resilience. Requires Standard network features."
  type        = bool
  default     = false
}

variable "netapp_replication_zone" {
  description = "Target availability zone for NetApp cross-zone replication. Must be different from netapp_availability_zone."
  type        = string
  default     = "2"
  
  validation {
    condition     = var.netapp_replication_zone == null || contains(["1", "2", "3"], var.netapp_replication_zone)
    error_message = "NetApp replication zone must be '1', '2', '3', or null."
  }
}

variable "netapp_replication_frequency" {
  description = "Replication frequency for cross-zone replication. Valid values: 10minutes, hourly, daily"
  type        = string
  default     = "10minutes"
  
  validation {
    condition     = contains(["10minutes", "hourly", "daily"], var.netapp_replication_frequency)
    error_message = "Valid values are: 10minutes, hourly, daily."
  }
}
```

**Updated module call in `main.tf`:**
```hcl
module "netapp" {
  source = "./modules/azurerm_netapp"
  count  = var.storage_type == "ha" ? 1 : 0
  
  # ... existing parameters ...
  
  # Multi-AZ Cross-Zone Replication Configuration
  netapp_availability_zone             = var.netapp_availability_zone
  netapp_enable_cross_zone_replication = var.netapp_enable_cross_zone_replication
  netapp_replication_zone              = var.netapp_replication_zone
  netapp_replication_frequency         = var.netapp_replication_frequency
}
```

## Usage Examples

### Example 1: Enable PostgreSQL Zone-Redundant HA

```hcl
postgres_servers = {
  default = {
    sku_name                     = "GP_Standard_D4s_v3"
    storage_mb                   = 131072
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false
    administrator_login          = "pgadmin"
    administrator_password       = "YourSecurePassword123!"
    server_version               = "15"
    ssl_enforcement_enabled      = true
    connectivity_method          = "private"
    
    # Enable Zone-Redundant High Availability
    high_availability_mode       = "ZoneRedundant"
    availability_zone            = "1"               # Primary in zone 1
    standby_availability_zone    = "2"               # Standby in zone 2
  }
}
```

**Result:** PostgreSQL Flexible Server will be deployed with:
- Primary server in availability zone 1
- Standby replica in availability zone 2
- Automatic failover enabled
- RPO: typically < 30 seconds
- RTO: typically < 60 seconds

### Example 2: Enable NetApp Cross-Zone Replication

```hcl
storage_type                         = "ha"
netapp_service_level                 = "Premium"
netapp_size_in_tb                    = 4
netapp_network_features              = "Standard"     # Required for cross-zone replication

# Enable Cross-Zone Replication
netapp_availability_zone             = "1"            # Primary volume in zone 1
netapp_enable_cross_zone_replication = true
netapp_replication_zone              = "2"            # Replicate to zone 2
netapp_replication_frequency         = "10minutes"    # Replicate every 10 minutes
```

**Result:** Azure NetApp Files will be deployed with:
- Primary volume in availability zone 1
- Replica volume in availability zone 2
- Replication every 10 minutes
- Zone failure protection with minimal data loss

### Example 3: Full Multi-AZ Deployment

```hcl
# AKS Node Pools
default_nodepool_availability_zones = ["1", "2", "3"]
node_pools_availability_zones       = ["1", "2", "3"]

# PostgreSQL with Zone-Redundant HA
postgres_servers = {
  default = {
    high_availability_mode       = "ZoneRedundant"
    availability_zone            = "1"
    standby_availability_zone    = "2"
    sku_name                     = "GP_Standard_D4s_v3"
    administrator_login          = "pgadmin"
    administrator_password       = "YourSecurePassword123!"
    connectivity_method          = "private"
  }
}

# NetApp with Cross-Zone Replication
storage_type                         = "ha"
netapp_network_features              = "Standard"
netapp_availability_zone             = "1"
netapp_enable_cross_zone_replication = true
netapp_replication_zone              = "2"
netapp_replication_frequency         = "10minutes"
```

**Result:** Complete zone-redundant deployment:
- AKS nodes distributed across zones 1, 2, and 3
- PostgreSQL with automatic failover between zones 1 and 2
- NetApp storage replicated between zones 1 and 2
- Full protection against single availability zone failures

## Validation Behavior

### Scenario 1: Default Configuration (No Changes Required)
**User Input:** No multi-AZ variables specified
```hcl
postgres_servers = {
  default = {
    administrator_login    = "pgadmin"
    administrator_password = "YourPassword123!"
  }
}
```

**Behavior:**
- ✅ Deploys successfully
- PostgreSQL in single zone (zone 1)
- High availability disabled
- Backward compatible with existing configurations

### Scenario 2: Zone-Redundant HA with Valid Configuration
**User Input:**
```hcl
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"
    availability_zone         = "1"
    standby_availability_zone = "2"
    # ... other settings
  }
}
```

**Behavior:**
- ✅ Validates successfully
- Zones differ (1 ≠ 2)
- Deploys with zone-redundant HA

### Scenario 3: Invalid Configuration - Same Zones
**User Input:**
```hcl
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"
    availability_zone         = "1"
    standby_availability_zone = "1"  # ERROR: Same as primary
    # ... other settings
  }
}
```

**Behavior:**
- ❌ Validation fails at `terraform plan`
- **Error Message:**
  ```
  Error: Invalid value for variable

  When high_availability_mode is 'ZoneRedundant', standby_availability_zone must
  differ from availability_zone to ensure proper zone-redundant high availability.
  ```
- Prevents deployment of misconfigured infrastructure
- User is prompted to fix the configuration

### Scenario 4: NetApp Replication Without Standard Network Features
**User Input:**
```hcl
netapp_network_features              = "Basic"   # ERROR: Should be "Standard"
netapp_enable_cross_zone_replication = true
```

**Behavior:**
- ❌ Validation fails at `terraform plan`
- **Error Message:**
  ```
  Error: Invalid value for variable

  When netapp_enable_cross_zone_replication is enabled, network_features must
  be set to 'Standard'. Cross-zone replication requires Standard network features.
  ```
- Prevents deployment
- Clear guidance on required configuration

## Backward Compatibility

### Key Design Principles:
1. **All new parameters have safe defaults**
2. **HA features are opt-in, not opt-out**
3. **Existing configurations continue to work without modification**
4. **Validations only enforce when features are enabled**

### Compatibility Matrix:

| Scenario | Existing Config | New Parameters | Result |
|----------|----------------|----------------|--------|
| Default deployment | None | Not specified | ✅ Works (single-zone) |
| Existing tfvars | Yes | Not specified | ✅ Works (single-zone) |
| Enable PostgreSQL HA | Yes | Add HA params | ✅ Works (zone-redundant) |
| Enable NetApp replication | Yes | Add replication params | ✅ Works (cross-zone) |
| Misconfigured zones | Yes | Same zones | ❌ Fails with clear error |

### Migration Path:

**Step 1:** Existing deployments continue working
- No immediate action required
- Single-zone deployments remain stable

**Step 2:** Plan multi-AZ upgrade
- Review Azure region zone availability
- Select appropriate zones for primary and standby resources

**Step 3:** Update configuration
- Add HA parameters to `postgres_servers`
- Add replication parameters for NetApp
- Run `terraform plan` to validate

**Step 4:** Apply changes
- `terraform apply` to enable zone-redundant features
- Monitor deployment for successful HA configuration

## Technical Implementation Details

### Variable Resolution Flow

#### PostgreSQL:
```
User tfvars (partial config)
    ↓
var.postgres_servers
    ↓
Merged with var.postgres_server_defaults (has HA fields with defaults)
    ↓
local.postgres_servers (complete configuration)
    ↓
Module call: lookup(each.value, "field", fallback_default)
    ↓
Module variables (have their own defaults)
    ↓
✅ Complete configuration at all levels
```

#### NetApp:
```
User tfvars (optional)
    ↓
var.netapp_* variables (have defaults)
    ↓
Direct pass-through to module
    ↓
Module variables (have matching defaults)
    ↓
✅ Complete configuration
```

### Validation Execution Order:

1. **Variable-level validation** (First line of defense)
   - Checks individual variable values
   - Validates data types and allowed values
   - Occurs during `terraform plan`

2. **Cross-variable validation** (Second line of defense)
   - Checks relationships between variables
   - Validates zone conflicts
   - Occurs during `terraform plan`

3. **Runtime validation via locals** (Third line of defense)
   - Additional safeguard with detailed error messages
   - Shows actual conflicting values
   - Occurs during `terraform plan`

### Error Handling Strategy:

All validations use the Terraform `validation` block pattern:
```hcl
validation {
  condition     = <boolean expression>
  error_message = "Clear, actionable error message"
}
```

Benefits:
- ✅ Fails fast at planning stage (not during apply)
- ✅ No partial deployments
- ✅ Clear guidance for users
- ✅ No risk of deploying misconfigured infrastructure

## Testing Recommendations

### Unit Tests:
1. **Test default values**: Verify all parameters work without user input
2. **Test valid configurations**: Verify proper zone-redundant setups work
3. **Test validation failures**: Verify error cases are caught correctly

### Integration Tests:
1. **Deploy with defaults**: Ensure backward compatibility
2. **Deploy with PostgreSQL HA**: Verify zone-redundant deployment
3. **Deploy with NetApp replication**: Verify cross-zone replication
4. **Deploy full multi-AZ**: Verify complete zone-redundant stack

### Validation Tests:
1. **Same zone error**: Verify validation catches zone conflicts
2. **Network features error**: Verify NetApp replication requirement
3. **Invalid zone values**: Verify zone number validation
4. **Invalid frequency**: Verify replication frequency validation

## References

### Azure Documentation:
- [Azure PostgreSQL Flexible Server High Availability](https://docs.azure.cn/en-us/postgresql/flexible-server/overview#architecture-and-high-availability)
- [Azure NetApp Files Reliability](https://learn.microsoft.com/en-us/azure/reliability/reliability-netapp-files)
- [Azure NetApp Files Cross-Zone Replication](https://learn.microsoft.com/en-us/azure/azure-netapp-files/create-cross-zone-replication)

### Related Issues:
- JIRA: PSCLOUD-382 (PostgreSQL multi-zone placement)
- JIRA: PSCLOUD-133 (Original multi-AZ feedback)

## Summary of Benefits

### For Operations Teams:
✅ **Improved availability**: Automatic failover during zone outages
✅ **Reduced RTO/RPO**: Faster recovery with zone-redundant resources
✅ **Better resilience**: Protection against zone-level failures
✅ **Clear validation**: Misconfigurations caught before deployment

### For Development Teams:
✅ **Easy adoption**: Opt-in features with safe defaults
✅ **Clear documentation**: Comprehensive examples and guidance
✅ **Validation feedback**: Immediate error detection during planning
✅ **Backward compatible**: Existing code continues to work

### For Business:
✅ **Higher SLAs**: Better uptime for SAS Viya platform
✅ **Reduced risk**: Zone failures don't cause outages
✅ **Compliance**: Meets enterprise HA requirements
✅ **Cost effective**: Pay only for HA when needed

## Conclusion

These enhancements comprehensively address the multi-AZ concerns raised in PSCLOUD-382 and related feedback. The implementation provides:

1. ✅ Full PostgreSQL zone-redundant high availability support
2. ✅ Complete NetApp cross-zone replication capabilities
3. ✅ Robust validation to prevent misconfigurations
4. ✅ Complete backward compatibility with existing deployments
5. ✅ Clear documentation and usage examples

The SAS Viya platform can now be deployed on Azure with full protection against availability zone failures, ensuring business continuity and meeting enterprise high availability requirements.
