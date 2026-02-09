# IPv6 Dual-Stack Usage Guide for viya4-iac-azure

**Complete guide for implementing, deploying, and validating IPv6 dual-stack networking on Azure AKS**

---

## Document Overview

This comprehensive guide covers the complete lifecycle of IPv6 dual-stack implementation for SAS Viya deployments on Azure Kubernetes Service (AKS):

- **Part 1**: Understanding IPv6 implementation (architecture, requirements, design decisions)
- **Part 2**: Deployment procedures (configuration, step-by-step deployment)
- **Part 3**: Validation and testing (verification, troubleshooting, operational checks)

---

## Table of Contents

### Part 1: Implementation Overview
1. [Background and Motivation](#1-background-and-motivation)
2. [Technical Requirements](#2-technical-requirements)
3. [Architecture Overview](#3-architecture-overview)
4. [Known Limitations](#4-known-limitations)

### Part 2: Deployment Guide
7. [Prerequisites](#7-prerequisites)
8. [Configuration](#8-configuration)

### Part 3: Validation and Operations
9. [Infrastructure Validation](#9-infrastructure-validation)
10. [Cluster Validation](#10-cluster-validation)
11. [Workload Validation](#11-workload-validation)
12. [Troubleshooting](#12-troubleshooting)

### Appendix
- [Reference Architecture Comparison](#appendix)
- [Subnet Calculation Examples](#a-subnet-calculation-examples)
- [Glossary](#b-glossary)
- [Quick Reference Commands](#c-quick-reference-commands)

---

# Part 1: Implementation Overview

## 1. Background and Motivation

### 1.1 Why IPv6?

- **IPv4 Address Exhaustion**: Growing cloud deployments are straining available IPv4 address space
- **Future-Proofing**: IPv6 is the long-term standard for internet protocols
- **Azure Support**: Azure now provides native IPv6 dual-stack support for AKS
- **Compliance**: Some customers require IPv6 for regulatory or organizational policies
- **Cost Optimization**: Dual-stack can reduce dependencies on NAT gateways and IPv4 public IPs

### 1.2 Business Drivers

1. **Customer Requirements**: Enable SAS Viya deployments in IPv6-required environments
2. **Scalability**: Support larger pod and service IP address spaces
3. **Modernization**: Align with industry best practices for cloud networking
4. **Competitive Advantage**: Support modern networking requirements ahead of competitors

### 1.3 Use Cases

**Internal Corporate Deployments**:
- Private networks requiring IPv6 for compliance
- Organizations transitioning to IPv6 infrastructure
- Future-proof internal SAS Viya deployments

**Internet-Facing Services**:
- Public SAS Viya services requiring global IPv6 accessibility
- Multi-region deployments with IPv6 connectivity
- Services needing both IPv4 and IPv6 client support

---

## 2. Technical Requirements

### 2.1 Azure Platform Requirements

| Component | Requirement | Version/Notes |
|-----------|-------------|---------------|
| AKS Kubernetes | 1.21+ | Dual-stack support |
| Azure CNI | Overlay Mode | **Required for IPv6** |
| Load Balancer SKU | Standard | Default (Basic not supported) |
| Terraform Provider | azurerm >= 3.0 | ARM template workaround needed |
| Azure API | 2023-07-01+ | Dual-stack network profile |
| Azure Subscription | IPv6 enabled | Contact Azure support if needed |

### 2.2 Networking Prerequisites

1. **Network Plugin Configuration**:
   ```hcl
   aks_network_plugin      = "azure"    # Azure CNI required
   aks_network_plugin_mode = "overlay"  # Mandatory for IPv6
   ```

2. **Load Balancer**:
   - Standard SKU (default in AKS)
   - Dual-stack outbound IPs (1 IPv4 + 1 IPv6)

3. **IP Address Planning**:
   - VNet IPv6 address space (/48 recommended)
   - Pod overlay IPv6 CIDR (/64)
   - Service IPv6 CIDR (/108)

### 2.3 Software Requirements

- Terraform >= 1.0
- Azure CLI >= 2.40 (optional, for validation)
- kubectl >= 1.21 (for dual-stack support)
- jq (optional, for automated validation scripts)

---

## 3. Architecture Overview

### 3.1 High-Level Architecture

```
+-------------------------------------------------------------+
|                    Azure Subscription                        |
|                                                               |
|  +----------------------------------------------------------+   |
|  |  Virtual Network (Dual-Stack)                        |   |
|  |  IPv4: 192.168.0.0/16                                |   |
|  |  IPv6: fd00:xxxx:xxxx::/48 (ULA)                     |   |
|  |                                                       |   |
|  |  +--------------------+  +----------------------+   |   |
|  |  | AKS Subnet         |  | Misc Subnet          |   |   |
|  |  | IPv4: .0.0/23      |  | IPv4: .2.0/24        |   |   |
|  |  | IPv6: ::/64        |  | IPv6: :0:1::/64      |   |   |
|  |  |                    |  |                      |   |   |
|  |  | +----------------+ |  | - Jump VM (IPv4)    |   |   |
|  |  | | AKS Cluster    | |  | - NFS VM (IPv4)     |   |   |
|  |  | | (Dual-Stack)   | |  | - PostgreSQL (IPv4) |   |   |
|  |  | |                | |  |                      |   |   |
|  |  | | Worker Nodes:  | |  |                      |   |   |
|  |  | | VNet IPs       | |  |                      |   |   |
|  |  | | 192.168.0.x    | |  |                      |   |   |
|  |  | | fd00:xxxx::x   | |  |                      |   |   |
|  |  | |                | |  |                      |   |   |
|  |  | | Pods:          | |  |                      |   |   |
|  |  | | Overlay IPs    | |  |                      |   |   |
|  |  | | 10.244.x.x     | |  |                      |   |   |
|  |  | | fd00:10:244::x | |  |                      |   |   |
|  |  | |                | |  |                      |   |   |
|  |  | | Services:      | |  |                      |   |   |
|  |  | | 10.0.x.x       | |  |                      |   |   |
|  |  | | fd00:10:0::x   | |  |                      |   |   |
|  |  | +----------------+ |  |                      |   |   |
|  |  +--------------------+  +----------------------+   |   |
|  +----------------------------------------------------------+   |
|                                                               |
|  +----------------------------------------------------------+   |
|  |  Load Balancer (Standard SKU)                        |   |
|  |  - 1x IPv4 Public IP                                 |   |
|  |  - 1x IPv6 Public IP                                 |   |
|  +----------------------------------------------------------+   |
+-------------------------------------------------------------+
```

### 3.2 IP Address Allocation Strategy

#### Layer 1: VNet and Subnets (Infrastructure)

**VNet - Dual-stack address space**:
- IPv4: `192.168.0.0/16` (65,536 addresses)
- IPv6: `fd00:1234:5678::/48` (2^80 addresses) - Default ULA range
  
**AKS Subnet - Worker node addresses**:
- IPv4: `192.168.0.0/23` (512 addresses)
- IPv6: `fd00:1234:5678::/64` (2^64 addresses)
- Auto-calculated: `cidrsubnet(vnet_ipv6_address_space, 16, 0)`

**Misc Subnet - Infrastructure VMs**:
- IPv4: `192.168.2.0/24` (256 addresses)
- IPv6: `fd00:1234:5678:0:1::/64` (2^64 addresses)
- Auto-calculated: `cidrsubnet(vnet_ipv6_address_space, 16, 1)`

#### Layer 2: Overlay Networks (Kubernetes)

**Pod CIDR - Overlay network for pod IPs**:
- IPv4: `10.244.0.0/16` (65,536 addresses) - Default, user-configurable via `aks_pod_cidr`
- IPv6: `fd00:10:244::/64` (2^64 addresses) - Default, user-configurable via `aks_pod_ipv6_cidr`
- Uses Unique Local Addresses (ULA) to avoid VNet conflicts

**Service CIDR - Cluster service IPs**:
- IPv4: `10.0.0.0/16` (65,536 addresses) - Default, user-configurable via `aks_service_cidr`
- IPv6: `fd00:10:0::/108` (2^20 addresses) - Default, user-configurable via `aks_service_ipv6_cidr`
- Uses ULA range for isolation

### 3.3 Network Traffic Flow

```
Internet (IPv4/IPv6)
        |
        v
Azure Load Balancer (Dual-Stack)
   |    +-- IPv4 Frontend: x.x.x.x
   |    +-- IPv6 Frontend: fd00:xxxx:xxxx:: (or globally routable)
        |
        v
Worker Nodes (Dual-Stack VNet IPs)
   |    +-- IPv4: 192.168.0.x
   |    +-- IPv6: fd00:xxxx:xxxx::x
        |
        v
Pods (Dual-Stack Overlay IPs)
   |    +-- IPv4: 10.244.x.x
   |    +-- IPv6: fd00:10:244::x
        |
        v
Services (Dual-Stack Cluster IPs)
        +-- IPv4: 10.0.x.x
        +-- IPv6: fd00:10:0::x
```

### 3.4 IPv6 Address Selection Guide

> **CRITICAL: IPv6 Prefix Selection**
> 
> The `2001:db8::/32` range is **reserved for documentation only** (RFC 3849) and **MUST NOT be used in production**. Choose the appropriate prefix for your environment:

#### Option 1: ULA (Unique Local Address) - **RECOMMENDED for Internal Use**
```
fd00:xxxx:xxxx::/48  (Generate at https://www.unique-local-ipv6.com/)
```
- **Production-ready** for internal-only clusters
- Private and isolated (like RFC 1918 for IPv4)
- No coordination with external authorities needed
- Globally unique when properly generated
- NOT routable on the public internet
- **Best for**: Internal corporate clusters, private VNets, dev/test environments

**Default in viya4-iac-azure**: `fd00:1234:5678::/48`

#### Option 2: Azure-Assigned Prefix - For Internet-Facing Deployments
```
Contact Azure support -> Get /48 allocation
```
- Globally routable
- Production-ready for public services
- Official Azure allocation
- **Process**: See detailed steps in [Section 3.5](#35-how-to-request-azure-public-ipv6-space)

**Example Azure-assigned prefix**: `2603:10a6:20b:2::/48`

**When to use**:
- Internet-facing SAS Viya deployments
- Public IPv6 services required
- External IPv6 client access needed
- Multi-region IPv6 connectivity

#### Option 3: Organization Prefix - Enterprise Deployments
```
Your ISP/RIR allocated prefix (e.g., 2001:0xxx:xxxx::/48)
```
- Your own IPv6 space
- Full control
- Requires: Existing IPv6 allocation from ISP or Regional Internet Registry

#### Option 4: Documentation Range - **EXAMPLES ONLY**
```
2001:db8::/48
```
- Safe for documentation
- **NOT routable** anywhere
- **NEVER use in production** (RFC 3849)
- Use ONLY in documentation or completely isolated test labs

---

### 3.5 How to Request Azure Public IPv6 Space

If you need globally routable IPv6 addresses for internet-facing deployments, follow these steps:

#### Step 1: Open Azure Support Request

1. **Navigate to Azure Portal**: https://portal.azure.com
2. **Go to Support**: Click "Help + support" in left menu
3. **Create Support Request**: Click "+ Create a support request"

#### Step 2: Fill Out Support Request

**Basics Tab:**
- **Issue Type**: Select `Service and subscription limits (quotas)`
- **Subscription**: Select your Azure subscription
- **Quota Type**: Select `Networking`
- **Problem Type**: Select `IPv6 for Virtual Network`

**Details Tab:**
- **Summary**: "Request IPv6 address space allocation for AKS cluster"
- **Description**: 
  ```
  Request: IPv6 address space allocation for production AKS cluster
  
  Details:
  - Deployment: Azure Kubernetes Service (AKS)
  - Purpose: Internet-facing SAS Viya deployment with IPv6 dual-stack
  - Region: [Your Azure region, e.g., East US 2]
  - Requested prefix size: /48 (recommended) or /56 (minimum)
  - Business justification: [Explain your use case]
  
  Technical Details:
  - Virtual Network: [VNet name or "New VNet"]
  - Resource Group: [RG name]
  - Expected usage: Dual-stack AKS nodes and services
  ```

**Contact Information:**
- Fill in your contact details
- Preferred contact method: Email or Phone

#### Step 3: Wait for Azure to Assign Prefix

**Timeline**: 
- Typical response: 1-3 business days
- Assignment: Usually within 5-7 business days

**What Azure will provide**:
```
Example allocation:
  Prefix: 2603:10a6:20b:2::/48
  Region: eastus2
  Subscription: xxxxx-xxxxx-xxxxx
```

#### Step 4: Configure Your Deployment

Once you receive your IPv6 prefix from Azure:

```hcl
# terraform.tfvars

enable_ipv6             = true
aks_network_plugin      = "azure"
aks_network_plugin_mode = "overlay"

# Use your Azure-assigned prefix
vnet_ipv6_address_space = "2603:10a6:20b:2::/48"  # Replace with YOUR assigned prefix

# Keep ULA for overlay networks (internal use)
aks_pod_ipv6_cidr       = "fd00:10:244::/64"
aks_service_ipv6_cidr   = "fd00:10:0::/108"
```

#### Step 5: Verify Assignment

After deployment, verify the IPv6 addresses:

```bash
# Check VNet has Azure-assigned prefix
az network vnet show \
  --resource-group $RG \
  --name $VNET_NAME \
  --query "addressSpace.addressPrefixes"

# Expected output:
# [
#   "192.168.0.0/16",
#   "2603:10a6:20b:2::/48"  # Your assigned prefix
# ]

# Check node IPs are from assigned range
kubectl get nodes -o wide
# Should show IPv6 addresses like: 2603:10a6:20b:2::8
```

#### Important Notes

**Prefix Size Recommendations**:
- **/48**: Recommended for production (provides 65,536 /64 subnets)
- **/56**: Minimum acceptable (provides 256 /64 subnets)
- **/64**: Single subnet only (not recommended for multi-subnet deployments)

**Costs**:
- IPv6 prefix allocation is **free**
- No additional charges for IPv6 addresses in Azure
- Standard Azure networking charges apply

**Best Practices**:
- Request /48 for future growth
- Document your assigned prefix in your organization's IP management system
- Use the same prefix for all VNets in the same region (if possible)
- Keep overlay networks (pods/services) on ULA ranges (fd00::/8)

**Alternative: Use ULA for Internal Deployments**

If you don't need internet-facing IPv6:
```hcl
# No support request needed - use default ULA
vnet_ipv6_address_space = "fd00:1234:5678::/48"  # Generate unique at https://www.unique-local-ipv6.com/
```

---

### 3.6 Deployment Flow

Understanding the deployment sequence helps troubleshoot issues and explains why certain dependencies exist:

```
┌─────────────────────────────────────────────────────────────────┐
│ Phase 1: Pre-Infrastructure (Standard for both IPv4 and IPv6)  │
└─────────────────────────────────────────────────────────────────┘
        │
        v
User sets enable_ipv6 = true in terraform.tfvars
        │
        v
terraform init && terraform plan
        │
        v
┌─────────────────────────────────────────────────────────────────┐
│ Phase 2: Base Azure Resources                                   │
│ - Resource Groups (AKS RG, Network RG)                          │
│ - Network Security Group (NSG)                                  │
│ - User Assigned Identity (UAI) for AKS                          │
│ - Proximity Placement Groups (if enabled)                       │
└─────────────────────────────────────────────────────────────────┘
        │
        v
┌─────────────────────────────────────────────────────────────────┐
│ Phase 3: Networking (IPv6-specific path diverges here)         │
└─────────────────────────────────────────────────────────────────┘
        │
        ├─── IPv6 Path (enable_ipv6=true)
        │         │
        │         v
        │    ARM Template: Create dual-stack VNet
        │    - VNet with IPv4 + IPv6 address spaces
        │    - Subnets with dual-stack prefixes
        │    - aks-subnet:      192.168.0.0/23 + fd00:xxxx::/64
        │    - misc-subnet:     192.168.2.0/24 + fd00:xxxx:1::/64
        │    - netapp-subnet:   192.168.3.0/24 + fd00:xxxx:2::/64
        │    - postgresql-subnet: 192.168.4.0/24 + fd00:xxxx:3::/64
        │         │
        │         v
        │    Data Sources: Fetch VNet/Subnet IDs
        │    - data.azurerm_virtual_network.ipv6_vnet
        │    - data.azurerm_subnet.aks_ipv6
        │    - data.azurerm_subnet.misc_ipv6
        │    - data.azurerm_subnet.netapp_ipv6
        │    - data.azurerm_subnet.postgresql_ipv6
        │         │
        └─── IPv4 Path (enable_ipv6=false)
                  │
                  v
             Module: azurerm_vnet
             - Standard Terraform VNet resource
             - IPv4-only subnets
                  │
                  v
        ┌─────────────────────────────────────────────────────────┐
        │ Both paths converge here                                │
        └─────────────────────────────────────────────────────────┘
        │
        v
┌─────────────────────────────────────────────────────────────────┐
│ Phase 4: AKS Cluster Creation (Initially IPv4 only)            │
│ - AKS cluster with system node pool                            │
│ - Network plugin: Azure CNI (Overlay mode for IPv6)            │
│ - Load balancer: Standard SKU                                  │
│ - IPv4 configuration applied                                   │
│ - IPv6 NOT YET configured (comes in Phase 6)                   │
└─────────────────────────────────────────────────────────────────┘
        │
        v
┌─────────────────────────────────────────────────────────────────┐
│ Phase 5: Additional Resources                                  │
│ - All AKS Node Pools (cas, compute, stateless, stateful)      │
│ - Jump VM (if enabled)                                         │
│ - NFS VM (if storage_type=standard)                            │
│ - Azure NetApp Files (if storage_type=ha)                      │
│ - PostgreSQL Flexible Server (if configured)                   │
│ - Container Registry (if enabled)                              │
│                                                                 │
│ CRITICAL: All node pools must complete before Phase 6          │
└─────────────────────────────────────────────────────────────────┘
        │
        v
┌─────────────────────────────────────────────────────────────────┐
│ Phase 6: IPv6 Configuration (Only if enable_ipv6=true)         │
│ ARM Template Patch: Configure AKS for Dual-Stack               │
│ - ipFamilies: ["IPv4", "IPv6"]                                 │
│ - ipFamilyPolicy: "RequireDualStack"                           │
│ - podCidrs: [IPv4 CIDR, IPv6 CIDR]                             │
│ - serviceCidrs: [IPv4 CIDR, IPv6 CIDR]                         │
│ - loadBalancerProfile:                                          │
│     - managedOutboundIPs: count=1 (IPv4)                       │
│     - countIPv6=1 (IPv6)                                        │
│                                                                 │
│ depends_on: [module.aks, module.node_pools]                    │
└─────────────────────────────────────────────────────────────────┘
        │
        v
┌─────────────────────────────────────────────────────────────────┐
│ Phase 7: Post-Configuration                                    │
│ - Kubeconfig generation                                         │
│ - Kubernetes ConfigMap (sas-iac-buildinfo)                     │
│ - NSG rules for IPv6 (if enabled)                              │
└─────────────────────────────────────────────────────────────────┘
        │
        v
┌─────────────────────────────────────────────────────────────────┐
│ Deployment Complete - Cluster Ready                            │
│                                                                 │
│ IPv6 Deployment:                                                │
│ - Dual-stack VNet and subnets                                  │
│ - AKS cluster with dual-stack networking                       │
│ - Pods receive both IPv4 and IPv6 addresses                    │
│ - Services can use dual-stack                                  │
│ - Load balancer has IPv4 + IPv6 public IPs                     │
│ - Infrastructure services (VMs, NetApp, PG) IPv4 only          │
└─────────────────────────────────────────────────────────────────┘
```

**Key Points**:

1. **Two-Stage AKS Configuration**: 
   - Stage 1 (Phase 4): Cluster created with IPv4 networking
   - Stage 2 (Phase 6): Cluster patched to add IPv6 dual-stack
   - This is required because Terraform azurerm provider doesn't support dual-stack natively

2. **Critical Dependency**: 
   - Phase 6 (IPv6 patch) MUST wait for all node pools to complete (Phase 5)
   - Implemented via `depends_on = [module.aks, module.node_pools]`
   - Prevents race conditions and 404 errors

3. **ARM Templates Used**:
   - `vnet_ipv6` (Phase 3): Creates dual-stack VNet/subnets
   - `aks_ipv6_dual_stack` (Phase 6): Configures AKS dual-stack
   - Required because native Terraform resources don't support these features yet

4. **Data Sources**:
   - Used to reference ARM-created resources in Terraform state
   - Allows Terraform to manage dependencies correctly
   - Required for subnet references in node pools and VMs

5. **Why Not Single-Step?**:
   - Azure API requires cluster to exist before applying dual-stack configuration
   - Node pools must be created before network profile can be updated
   - ARM template "Incremental" mode safely updates existing cluster

---

## 4. Known Limitations

### 4.0 PostgreSQL + IPv6 Fundamental Incompatibility

**CRITICAL - DEPLOYMENT BLOCKER**: Azure PostgreSQL Flexible Server and IPv6 are **MUTUALLY EXCLUSIVE**.

**Official Azure Documentation Statement**:
> "Azure Database for PostgreSQL - Flexible Server doesn't currently support IPv6. Even if the subnet for the Postgres Flexible Server doesn't have any IPv6 addresses assigned, it can't be deployed if there are IPv6 addresses in the virtual network."
>
> Source: [Azure Virtual Network IPv6 Overview](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/ipv6-overview)

**What This Means**:
- PostgreSQL Flexible Server **CANNOT be deployed** in any VNet with IPv6 address space
- This applies **even if** the PostgreSQL subnet has no IPv6 addresses assigned
- The restriction is at the **VNet level**, not the subnet level
- You **MUST choose** between PostgreSQL and IPv6 - you cannot have both

**Impact on Deployment**:

| Scenario | PostgreSQL | IPv6 | Result |
|----------|-----------|------|--------|
| IPv6 Enabled | ❌ **BLOCKED** | ✅ Supported | PostgreSQL deployment will fail |
| IPv6 Disabled | ✅ Supported | ❌ Not available | PostgreSQL deploys successfully |

**Deployment Options**:

**Option A: IPv6 Dual-Stack (No PostgreSQL)**
```hcl
enable_ipv6 = true
vnet_ipv6_address_space = "2001:db8::/48"
# Comment out or remove postgres_servers block entirely
# postgres_servers = { ... }  # DO NOT configure
```
- ✅ Full IPv6 dual-stack networking for AKS
- ❌ No managed PostgreSQL available
- Alternative: Use PostgreSQL in separate IPv4-only VNet with VNet peering

**Option B: PostgreSQL HA (No IPv6)**
```hcl
enable_ipv6 = false  # Must be false
# Do NOT configure vnet_ipv6_address_space or IPv6 CIDRs
postgres_servers = {
  default = {
    high_availability_mode    = "ZoneRedundant"
    availability_zone         = "1"
    standby_availability_zone = "2"
  }
}
```
- ✅ PostgreSQL with zone-redundant HA
- ❌ IPv4-only networking
- ✅ Multi-zone resilience still available for AKS and storage

**Mitigation Strategies**:

1. **Separate VNets** (Most Common):
   - Deploy PostgreSQL in dedicated IPv4-only VNet
   - Deploy AKS with IPv6 in separate VNet
   - Connect via VNet peering or Private Link
   - ⚠️ Adds network complexity and potential latency

2. **Use External PostgreSQL**:
   - Host PostgreSQL outside Azure (on-premises or other cloud)
   - AKS cluster can use IPv6
   - ⚠️ Lose Azure-managed HA benefits

3. **Wait for Azure Support**:
   - Monitor Azure roadmap for IPv6 support in PostgreSQL Flexible Server
   - No ETA available as of February 2026

**Regional Considerations**:

Even if you choose Option B (PostgreSQL, no IPv6), not all regions support PostgreSQL High Availability:

- ✅ **East US 2** - Supports PostgreSQL HA
- ✅ **West US 3** - Supports PostgreSQL HA
- ❌ **West US 2** - PostgreSQL HA blocked

See [MULTI-AZ-CONFIG.md](../MULTI-AZ-CONFIG.md#postgresql-ha-regional-availability) for complete regional availability.

---

### 4.1 Infrastructure Components (IPv4 Only)

**CRITICAL**: Even though subnets are configured as dual-stack (IPv4 + IPv6), most Azure infrastructure services only support IPv4 connectivity as of 2026.

| Component | IPv4 | IPv6 | Reason | Impact |
|-----------|------|------|--------|--------|
| **Jump VM** | YES | NO | Azure VMs don't auto-assign IPv6 to NICs | SSH accessible via IPv4 only |
| **NFS VM** | YES | NO | Azure VMs don't auto-assign IPv6 to NICs | NFS mounts use IPv4 endpoint |
| **PostgreSQL Flexible** | YES | NO | **CANNOT deploy in IPv6 VNets** (see 4.0 above) | PostgreSQL + IPv6 are mutually exclusive |
| **Azure NetApp Files** | YES | NO | Azure service limitation (no IPv6 support) | NFS endpoint IPv4 only (192.168.x.x) |
| **Container Registry** | YES | NO | Azure service limitation | Container pulls via IPv4 |

**What This Means**:
- IPv6 subnet ranges are **allocated but unused** by infrastructure services
- Pods with IPv6 addresses must use **IPv4 to connect** to these services
- Kubernetes automatically selects IPv4 for connections to IPv4-only endpoints
- The dual-stack subnet configuration is **future-proof** for when Azure adds IPv6 support

**Workaround**: Dual-stack pods have both IPv4 and IPv6 addresses, allowing them to communicate with IPv4-only services without issues.

### 4.2 AKS Components (Full Dual-Stack Support)

| Component | IPv4 | IPv6 | Status |
|-----------|------|------|--------|
| **AKS Pods** | YES | YES | Full dual-stack |
| **AKS Services (LoadBalancer)** | YES | YES | Dual-stack frontend IPs |
| **AKS ClusterIP Services** | YES | YES | Both IP families |
| **Node-to-Node** | YES | YES | Dual-stack communication |
| **Pod-to-Pod** | YES | YES | Dual-stack communication |

### 4.3 Default Kubernetes Service

**Observation**: `kubernetes.default.svc` service remains IPv4-only.  
**Reason**: System service created before IPv6 configuration is applied to the cluster.  
**Impact**: None - this is expected behavior and doesn't affect cluster operations or workload connectivity.

### 4.4 External IPv6 Connectivity

**Status**: Internal connectivity works; external depends on Azure configuration.

**Test Results**:
- Pod-to-pod IPv6: Working
- Pod-to-service IPv6: Working
- Node-to-node IPv6: Working
- External IPv6 egress: Environment-dependent

**Requirements for External IPv6**:
- Azure VNet IPv6 egress routing configured
- Load balancer with public IPv6 frontend (created automatically)
- Internet-facing services need `ipFamilyPolicy: PreferDualStack` or `RequireDualStack`

### 4.5 Terraform Destroy Limitation (Azure Provider Issue)

**Issue**: Node pool 404 errors during `terraform destroy`

**Symptom**:
```
Error: deleting Agent Pool: unexpected status 404 (404 Not Found) 
with error: ResourceNotFound: The Resource 
'Microsoft.ContainerService/managedClusters/xxx-aks' was not found.
```

**Root Cause**: 
- Azure automatically cascade-deletes all node pools when the parent AKS cluster is deleted
- The azurerm Terraform provider (v4.57.0) attempts to explicitly delete the already-deleted node pools
- The provider does not gracefully handle 404 errors for resources that were already removed by Azure
- **This issue is specific to IPv6 deployments** due to how subnet data sources are referenced

**Why This Happens in IPv6 Deployments**:
1. IPv6 uses data source references: `data.azurerm_subnet.aks_ipv6[0].id`
2. These data sources query the ARM-created VNet during destroy
3. When the VNet/subnets are destroyed, the data source queries fail or return empty
4. This can cause Terraform's dependency graph to become fragile during destroy
5. Without stable references, Terraform may delete the cluster before node pools complete
6. Azure's cascade delete immediately removes all child node pools
7. Terraform then tries to delete node pools that no longer exist
8. Provider throws 404 error instead of treating it as success

**Why IPv4 Deployments Don't Have This Issue**:
- IPv4 uses direct module references: `local.vnet.subnets["aks"].id`
- Module outputs maintain stable references throughout the destroy process
- Terraform's dependency tracking ensures cluster waits for node pools
- No data source queries during destroy means no fragile dependencies
- Node pools are destroyed before cluster, so no 404 errors occur

**Impact**: 
- Destroy operation fails but most resources are already deleted
- Orphaned node pool references remain in Terraform state
- Requires manual state cleanup to complete destroy

**Workaround**:

When you encounter node pool 404 errors during destroy, you need to clean up both node pool state and Kubernetes resource state:

```bash
# Step 1: Remove node pool state references (handles 404 errors)
terraform state list | grep azurerm_kubernetes_cluster_node_pool | while read resource; do 
  terraform state rm "$resource"
done

# Step 2: Remove Kubernetes resource state references (handles connection refused errors)
# These resources lived inside the deleted cluster and can't be deleted
terraform state list | grep -E 'kubernetes_config_map|kubernetes_service_account|kubernetes_cluster_role_binding|kubernetes_secret' | while read resource; do 
  terraform state rm "$resource"
done

# Step 3: Retry destroy
terraform destroy
```

**PowerShell version:**
```powershell
# Step 1: Remove node pool state
terraform state list | Select-String "azurerm_kubernetes_cluster_node_pool" | ForEach-Object { terraform state rm $_.Line }

# Step 2: Remove Kubernetes resource state
terraform state list | Select-String -Pattern "kubernetes_config_map|kubernetes_service_account|kubernetes_cluster_role_binding|kubernetes_secret" | ForEach-Object { terraform state rm $_.Line }

# Step 3: Retry destroy
terraform destroy
```

**Common errors after cluster deletion:**
- `404 Not Found` - Node pools already cascade-deleted, Fixed by removing node pool state
- `connection refused` - Kubernetes resources in deleted cluster, Fixed by removing Kubernetes resource state
- `Invalid index` on `data.azurerm_subnet.aks_ipv6[0]` - Data source queries fail, Continue with destroy after state cleanup

**Note**: This limitation is specific to IPv6 deployments due to the use of ARM template data source queries during destroy, which can cause fragile dependency chains. IPv4-only deployments use stable module references and don't experience this issue.

**Future**: This could be resolved by:
1. Converting VNet creation to use native Terraform resources that support dual-stack (when azurerm provider adds support)
2. Using computed locals with stable fallbacks to prevent data source evaluation during destroy
3. Updating the azurerm provider to treat 404 errors on node pool deletion as success rather than failure

### 4.6 Azure Regional Availability Limitations

**CRITICAL**: Not all Azure features are available in all regions. Verify your target region supports the required features before deployment.

#### 4.6.1 IPv6 Dual-Stack Regional Availability

**IPv6 for Azure VNet - Generally Available (GA)**

As of 2026, IPv6 dual-stack for Azure Virtual Networks and AKS is **generally available** in most Azure regions, but there are considerations:

| Feature | Regional Status | Notes |
|---------|----------------|-------|
| **IPv6 VNet Addressing** | Available in most regions | Check Azure portal for your region |
| **AKS Dual-Stack (IPv4+IPv6)** | Available in most regions | Requires Azure CNI Overlay mode |
| **IPv6 Public IPs** | Available in most regions | Standard SKU required |
| **IPv6 Load Balancer** | Available in most regions | Automatically enabled with dual-stack |

**Recommended Regions for IPv6 Deployments** (Known to support all required features):
- **US**: East US, East US 2, West US 2, West US 3, Central US, South Central US
- **Europe**: North Europe, West Europe, UK South, France Central
- **Asia Pacific**: Southeast Asia, East Asia, Australia East, Japan East
- **Other**: Canada Central, Brazil South, UAE North

**How to Verify IPv6 Support for Your Region**:

```bash
# Method 1: Check via Azure CLI
az account list-locations -o table | grep -i "your-region-name"

# Method 2: Check Azure Portal
# Navigate to: Home > Virtual Networks > Create
# Select your region and check if IPv6 address space option is available

# Method 3: Terraform test (safest method)
# Just attempt deployment - will fail immediately if region doesn't support IPv6
```

**If Your Region Doesn't Support IPv6**:
- Choose a different region from the recommended list
- Or disable IPv6: Set `enable_ipv6 = false` in your tfvars

---

# Part 2: Deployment Guide

## 7. Prerequisites

### 7.1 Prerequisites Checklist

- [ ] **IPv6 address prefix planned** (see [Section 3.4](#34-ipv6-address-selection-guide)):
  - [ ] For **production with internet access**: Obtain IPv6 prefix from Azure support
  - [ ] For **production internal-only**: Use default ULA `fd00:1234:5678::/48` or generate unique prefix
  - [ ] For **testing/examples only**: Can use `2001:db8::/48` (NOT for production)

### 7.2 Network Planning

Before deployment, plan your IPv6 address space:

| Network | IPv4 (Default) | IPv6 (Default) | Customizable |
|---------|----------------|----------------|--------------|
| VNet | 192.168.0.0/16 | fd00:1234:5678::/48 | YES |
| Pod Overlay | 10.244.0.0/16 | fd00:10:244::/64 | IPv6 only |
| Service | 10.0.0.0/16 | fd00:10:0::/108 | IPv6 only |

---

## 8. Configuration

### 8.1 Minimal IPv6 Configuration

Create or update your `terraform.tfvars`:

```hcl
# ===== REQUIRED IPv6 SETTINGS =====
enable_ipv6             = true
aks_network_plugin      = "azure"
aks_network_plugin_mode = "overlay"

# ===== IPv6 ADDRESS CONFIGURATION =====
# Defaults are production-safe ULA ranges for internal-only clusters
# Uncomment and customize for your environment:

# vnet_ipv6_address_space = "fd00:1234:5678::/48"  # Default ULA range
# aks_pod_ipv6_cidr       = "fd00:10:244::/64"     # Default ULA for pods
# aks_service_ipv6_cidr   = "fd00:10:0::/108"      # Default ULA for services

# For internet-facing clusters, use Azure-assigned or org-allocated prefix
# Example: vnet_ipv6_address_space = "2001:0xxx:xxxx::/48"
```

### 8.2 Configuration Examples

#### Example 1: Internal Cluster (Default - Recommended)
```hcl
prefix   = "mycompany-viya"
location = "eastus2"

enable_ipv6             = true
aks_network_plugin      = "azure"
aks_network_plugin_mode = "overlay"
# Uses default ULA ranges - no additional config needed

kubernetes_version = "1.32"
```

#### Example 2: Internal Cluster with Custom ULA Prefix
```hcl
prefix   = "mycompany-viya"
location = "eastus2"

enable_ipv6             = true
aks_network_plugin      = "azure"
aks_network_plugin_mode = "overlay"

# Generate unique ULA: https://www.unique-local-ipv6.com/
vnet_ipv6_address_space = "fd00:abcd:ef01::/48"  # Your unique ULA
aks_pod_ipv6_cidr       = "fd00:10:244::/64"
aks_service_ipv6_cidr   = "fd00:10:0::/108"

kubernetes_version = "1.32"
```

#### Example 3: Internet-Facing Cluster
```hcl
prefix   = "public-viya"
location = "westus2"

enable_ipv6             = true
aks_network_plugin      = "azure"
aks_network_plugin_mode = "overlay"

# Use Azure-assigned or organization's globally routable prefix
vnet_ipv6_address_space = "2001:0xxx:xxxx::/48"  # Replace with YOUR assigned prefix
aks_pod_ipv6_cidr       = "fd00:10:244::/64"      # ULA for overlay (internal)
aks_service_ipv6_cidr   = "fd00:10:0::/108"       # ULA for services (internal)

kubernetes_version = "1.32"
```

---

# Part 3: Validation and Operations

## 9. Infrastructure Validation

### 9.1 Verify Virtual Network

```bash
# Set your variables
RESOURCE_GROUP="<your-rg-name>"
VNET_NAME="<your-prefix>-vnet"

# Check VNet address spaces
az network vnet show \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --query "addressSpace.addressPrefixes" \
  --output table

# Expected output:
# 192.168.0.0/16
# fd00:xxxx:xxxx::/48
```

**Success Criteria**:
- VNet has 2 address prefixes
- One IPv4 (192.168.0.0/16 or custom)
- One IPv6 (fd00::/8 ULA or assigned prefix)

### 9.2 Verify Subnets

```bash
# Check AKS subnet
az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name "<your-prefix>-aks-subnet" \
  --query "addressPrefixes" \
  --output table

# Expected: Dual-stack subnet
# 192.168.0.0/23
# fd00:xxxx:xxxx::/64

# Check Misc subnet
az network vnet subnet show \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name "<your-prefix>-misc-subnet" \
  --query "addressPrefixes" \
  --output table

# Expected: Dual-stack subnet
# 192.168.2.0/24
# fd00:xxxx:xxxx:0:1::/64
```

**Success Criteria**:
- Each subnet has 2 address prefixes (IPv4 + IPv6)
- IPv6 prefixes are /64 subnets

### 9.3 Verify Network Security Group

```bash
# Check for IPv6 NSG rule
az network nsg rule show \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "<your-prefix>-nsg" \
  --name "SAS-IPv6-LB-Outbound" \
  --output table
```

**Success Criteria**:
- Rule exists with direction=Outbound
- Source and destination: `::/0`

---

## 10. Cluster Validation

### 10.1 Verify AKS Network Profile

```bash
AKS_NAME="<your-prefix>-aks"

# Check IP families
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --query "networkProfile.ipFamilies" \
  --output table

# Expected: IPv4 and IPv6

# Check IP family policy
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --query "networkProfile.ipFamilyPolicy" \
  --output tsv

# Expected: RequireDualStack

# Check pod CIDRs
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --query "networkProfile.podCidrs" \
  --output table

# Expected:
# 10.244.0.0/16
# fd00:10:244::/64 (or your configured IPv6 pod CIDR)

# Check service CIDRs
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --query "networkProfile.serviceCidrs" \
  --output table

# Expected:
# 10.0.0.0/16
# fd00:10:0::/108 (or your configured IPv6 service CIDR)

# Check load balancer
az aks show \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --query "networkProfile.loadBalancerProfile.managedOutboundIPs" \
  --output yaml

# Expected: countIPv6: 1
```

**Success Criteria**:
- `ipFamilies`: ["IPv4", "IPv6"]
- `ipFamilyPolicy`: RequireDualStack
- `podCidrs`: 2 entries
- `serviceCidrs`: 2 entries
- `loadBalancerProfile`: countIPv6 = 1

### 10.2 Verify Node IP Addresses

```bash
# List all nodes with their IPs
kubectl get nodes -o wide

# Get detailed node IPs
kubectl get nodes -o custom-columns=\
NAME:.metadata.name,\
IPv4:.status.addresses[0].address,\
IPv6:.status.addresses[1].address

# Verify all nodes have both IPs
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
IPV6_COUNT=$(kubectl get nodes -o json | jq -r '[.items[].status.addresses[] | 
  select(.type=="InternalIP" and (.address | contains(":")))] | length')

echo "Nodes: $NODE_COUNT, IPv6 addresses: $IPV6_COUNT"
```

**Success Criteria**:
- Every node shows 2 InternalIP addresses
- First IP is IPv4 (192.168.0.x)
- Second IP is IPv6 (fd00:xxxx:xxxx::x)
- IPv6 count equals node count

---

## 11. Workload Validation

### 11.1 Deploy Test Pod

```bash
# Create test pod with network tools
kubectl run ipv6-test-pod --image=nicolaka/netshoot --restart=Never -- sleep 3600

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/ipv6-test-pod --timeout=60s

# Check pod IPs
kubectl get pod ipv6-test-pod -o jsonpath='{.status.podIPs[*].ip}' && echo

# Expected: Two IPs
# 10.244.x.x fd00:10:244::xxx
```

**Success Criteria**:
- Pod has 2 IP addresses
- First IP from IPv4 pod CIDR (10.244.0.0/16)
- Second IP from IPv6 pod CIDR (fd00:10:244::/64)

### 11.2 Test Pod-to-Pod IPv6 Connectivity

```bash
# Deploy second test pod
kubectl run ipv6-test-pod-2 --image=nicolaka/netshoot --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/ipv6-test-pod-2 --timeout=60s

# Get IPv6 address of second pod
TARGET_IPV6=$(kubectl get pod ipv6-test-pod-2 -o jsonpath='{.status.podIPs[1].ip}')
echo "Target IPv6: $TARGET_IPV6"

# Ping from first pod to second pod using IPv6
kubectl exec ipv6-test-pod -- ping6 -c 3 $TARGET_IPV6

# Expected: Successful ping with 0% packet loss
```

**Success Criteria**:
- Ping succeeds
- Shows IPv6 addresses
- RTT < 10ms typically

### 11.3 Create and Test Dual-Stack Service

> **Note**: Complete these steps in order

```bash
# Step 1: Create a deployment
kubectl create deployment ipv6-nginx --image=nginx --replicas=2

# Step 2: Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l app=ipv6-nginx --timeout=60s

# Step 3: Verify pods are running
kubectl get pods -l app=ipv6-nginx

# Step 4: Create dual-stack service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ipv6-nginx-svc
spec:
  ipFamilyPolicy: PreferDualStack
  ipFamilies: [IPv4, IPv6]
  selector:
    app: ipv6-nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Step 5: Verify service was created
kubectl get svc ipv6-nginx-svc

# Step 6: Check service cluster IPs
kubectl get svc ipv6-nginx-svc -o jsonpath='{.spec.clusterIPs[*]}' && echo

# Expected: Two IPs
# 10.0.x.x fd00:10:0::xxxx

# Step 7: Verify IP families
kubectl get svc ipv6-nginx-svc -o jsonpath='{.spec.ipFamilies[*]}' && echo
# Expected: IPv4 IPv6
```

**Success Criteria**:
- Service has 2 cluster IPs
- First IP from IPv4 service CIDR (10.0.0.0/16)
- Second IP from IPv6 service CIDR (fd00:10:0::/108)
- ipFamilies: [IPv4, IPv6]

### 11.4 Test Service Connectivity

> **Prerequisite**: Service must exist (complete section 11.3 first)

```bash
# Verify service exists
if ! kubectl get svc ipv6-nginx-svc &> /dev/null; then
    echo "ERROR: Service does not exist! Complete section 13.3 first."
    exit 1
fi

# Get service IPv6 address
SERVICE_IPV6=$(kubectl get svc ipv6-nginx-svc -o jsonpath='{.spec.clusterIPs[1]}')
echo "Service IPv6: $SERVICE_IPV6"

# Test HTTP connectivity via IPv6
kubectl exec ipv6-test-pod -- curl -6 -s -m 5 "http://[$SERVICE_IPV6]" | grep -i "welcome to nginx"

# Test DNS resolution
kubectl exec ipv6-test-pod -- nslookup ipv6-nginx-svc.default.svc.cluster.local

# Alternative: Use dig to see both A and AAAA records
kubectl exec ipv6-test-pod -- dig ipv6-nginx-svc.default.svc.cluster.local ANY +short
```

**Success Criteria**:
- HTTP request succeeds and returns nginx page
- DNS returns both IPv4 and IPv6 addresses
- Both A (IPv4) and AAAA (IPv6) records present

### 11.5 Verify System Pods

```bash
# Check CoreDNS pods have dual-stack IPs
kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath=\
'{range .items[*]}{.metadata.name}{"\t"}{.status.podIPs[*].ip}{"\n"}{end}'

# List system pods with IPs
kubectl get pods -n kube-system -o custom-columns=\
NAME:.metadata.name,\
IPs:.status.podIPs[*].ip | head -15
```

**Success Criteria**:
- CoreDNS pods have dual-stack IPs
- Most system pods have dual-stack IPs
- Some DaemonSets use hostNetwork (expected to have node IPs)

### 11.6 Automated Validation Script

Save as `validate-ipv6-cluster.sh`:

```bash
#!/bin/bash
# IPv6 Dual-Stack Cluster Validation Script

set -e

echo "=========================================="
echo "IPv6 Dual-Stack Cluster Validation"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}[ERROR] kubectl not found${NC}"
    exit 1
fi

echo -e "${YELLOW}1. Checking Cluster Access...${NC}"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}[OK] Cluster accessible${NC}"
else
    echo -e "${RED}[ERROR] Cannot access cluster${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}2. Checking Node IPv6 Addresses...${NC}"
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
IPV6_COUNT=$(kubectl get nodes -o json | jq -r '[.items[].status.addresses[] | 
  select(.type=="InternalIP" and (.address | contains(":")))] | length')

if [ "$NODE_COUNT" -eq "$IPV6_COUNT" ]; then
    echo -e "${GREEN}[OK] All $NODE_COUNT nodes have IPv6 addresses${NC}"
    kubectl get nodes -o custom-columns=NAME:.metadata.name,IPv4:.status.addresses[0].address,IPv6:.status.addresses[1].address
else
    echo -e "${RED}[ERROR] IPv6 mismatch: $NODE_COUNT nodes but only $IPV6_COUNT IPv6 addresses${NC}"
fi
echo ""

echo -e "${YELLOW}3. Checking System Pod IPs...${NC}"
COREDNS_DUAL=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o json | jq -r '.items[0].status.podIPs | length')
if [ "$COREDNS_DUAL" -eq 2 ]; then
    echo -e "${GREEN}[OK] CoreDNS pods have dual-stack IPs${NC}"
else
    echo -e "${RED}[ERROR] CoreDNS pods may not have dual-stack IPs${NC}"
fi
echo ""

echo -e "${YELLOW}4. Creating Test Pod...${NC}"
kubectl delete pod ipv6-validation-test --ignore-not-found &> /dev/null
kubectl run ipv6-validation-test --image=nicolaka/netshoot --restart=Never -- sleep 300 &> /dev/null
echo "Waiting for pod..."
if kubectl wait --for=condition=Ready pod/ipv6-validation-test --timeout=60s &> /dev/null; then
    echo -e "${GREEN}[OK] Test pod created${NC}"
    
    POD_IP_COUNT=$(kubectl get pod ipv6-validation-test -o json | jq '.status.podIPs | length')
    if [ "$POD_IP_COUNT" -eq 2 ]; then
        echo -e "${GREEN}[OK] Test pod has dual-stack IPs:${NC}"
        kubectl get pod ipv6-validation-test -o jsonpath='{.status.podIPs[*].ip}' && echo
    else
        echo -e "${RED}[ERROR] Test pod only has $POD_IP_COUNT IP(s)${NC}"
    fi
else
    echo -e "${RED}[ERROR] Test pod failed to start${NC}"
fi
echo ""

echo -e "${YELLOW}5. Testing IPv6 Connectivity...${NC}"
if [ "$POD_IP_COUNT" -eq 2 ]; then
    POD_IPV6=$(kubectl get pod ipv6-validation-test -o jsonpath='{.status.podIPs[1].ip}')
    if kubectl exec ipv6-validation-test -- ping6 -c 2 -W 2 "$POD_IPV6" &> /dev/null; then
        echo -e "${GREEN}[OK] IPv6 ping successful${NC}"
    else
        echo -e "${RED}[ERROR] IPv6 ping failed${NC}"
    fi
fi
echo ""

echo "=========================================="
echo -e "${GREEN}Validation Complete!${NC}"
echo "=========================================="
echo ""
echo "Cleanup: kubectl delete pod ipv6-validation-test"
```

Run the script:
```bash
chmod +x validate-ipv6-cluster.sh
./validate-ipv6-cluster.sh
```

---

## 12. Troubleshooting

### 12.1 Common Deployment Issues

#### Issue: Pod CIDR Overlap Error

**Symptom**:
```
Error: Pod CIDR fd00:1234:5678::/64 overlaps with subnet fd00:1234:5678::/64
```

**Cause**: Using VNet IPv6 range for pod CIDR

**Solution**: Use different ULA range for pods
```hcl
aks_pod_ipv6_cidr = "fd00:10:244::/64"  # Different from VNet range
```

#### Issue: Node Pool Creation Conflict

**Symptom**:
```
Error: Operation not allowed because there's an in progress create node pool operation
```

**Cause**: IPv6 patch attempted during node pool creation

**Solution**: Already implemented via `depends_on`. If error persists:
```bash
# Wait 5-10 minutes, then re-apply
terraform apply
```

#### Issue: Pods Only Have IPv4

**Symptoms**:
```bash
$ kubectl get pod test -o jsonpath='{.status.podIPs}'
[{"ip":"10.244.x.x"}]  # Only IPv4
```

**Diagnostics**:
```bash
# 1. Verify cluster configuration
az aks show -g $RESOURCE_GROUP -n $AKS_NAME --query "networkProfile.podCidrs"

# Should show: ["10.244.0.0/16", "fd00:10:244::/64"]

# 2. Check if IPv6 patch was applied
az aks show -g $RESOURCE_GROUP -n $AKS_NAME --query "networkProfile.ipFamilyPolicy"

# Should show: RequireDualStack
```

**Solutions**:
```bash
# 1. Delete and recreate pod
kubectl delete pod test
kubectl run test --image=nginx

# 2. If still failing, check CNI logs
kubectl logs -n kube-system -l component=azure-cns --tail=50

# 3. Verify ARM template deployment succeeded
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "<prefix>-aks-ipv6-patch" \
  --query "properties.provisioningState"
```

#### Issue: Services Don't Get IPv6

**Symptom**:
```bash
$ kubectl get svc my-svc
CLUSTER-IP: 10.0.x.x  # Only IPv4
```

**Cause**: Service missing dual-stack configuration

**Solution**: Patch existing service or create with policy
```bash
# Patch existing service
kubectl patch svc my-svc -p '{"spec":{"ipFamilyPolicy":"PreferDualStack","ipFamilies":["IPv4","IPv6"]}}'

# Or delete and recreate with proper configuration
```

#### Issue: DNS Resolution Fails

**Symptom**:
```bash
$ kubectl exec pod -- nslookup service-name
server can't find service-name: NXDOMAIN
```

**Cause**: Service doesn't exist yet or wrong namespace

**Solution**:
```bash
# 1. Verify service exists
kubectl get svc service-name -n <namespace>

# 2. Use FQDN
kubectl exec pod -- nslookup service-name.<namespace>.svc.cluster.local

# 3. Check CoreDNS is running
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

#### Issue: External IPv6 Not Reachable

**Symptom**: LoadBalancer service has IPv6 but external access fails

**Diagnostics**:
```bash
# Check load balancer
MC_RG=$(az aks show -g $RESOURCE_GROUP -n $AKS_NAME --query nodeResourceGroup -o tsv)
az network lb list -g $MC_RG
az network lb frontend-ip list -g $MC_RG --lb-name kubernetes

# Check NSG rules
az network nsg rule list -g $RESOURCE_GROUP --nsg-name <nsg>
```

**Solutions**:
- Contact Azure support for IPv6 egress configuration
- Verify NSG allows IPv6 traffic
- Test from IPv6-enabled network

### 12.2 Debugging Commands

#### Verify Infrastructure
```bash
# VNet
az network vnet show -g $RESOURCE_GROUP -n $VNET_NAME \
  --query "addressSpace.addressPrefixes"

# Subnets
az network vnet subnet show -g $RESOURCE_GROUP --vnet-name $VNET_NAME \
  -n <subnet-name> --query "addressPrefixes"

# AKS network profile
az aks show -g $RESOURCE_GROUP -n $AKS_NAME \
  --query "networkProfile" -o yaml
```

#### Verify Kubernetes Resources
```bash
# Node IPs
kubectl get nodes -o custom-columns=\
NAME:.metadata.name,\
IPv4:.status.addresses[0].address,\
IPv6:.status.addresses[1].address

# Pod IPs
kubectl get pods -A -o jsonpath=\
'{range .items[*]}{.metadata.name}{"\t"}{.status.podIPs[*].ip}{"\n"}{end}'

# Service IPs
kubectl get svc -A -o custom-columns=\
NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
CLUSTER-IPs:.spec.clusterIPs[*],\
IP-FAMILIES:.spec.ipFamilies[*]
```

#### Check CNI Status
```bash
# Azure CNI logs
kubectl logs -n kube-system -l component=azure-cns --tail=100

# CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# Kube-proxy logs (for service routing)
kubectl logs -n kube-system -l component=kube-proxy --tail=50
```

### 12.3 Recovery Procedures

#### Reset Failed Deployment

If deployment fails midway:

```bash
# 1. Check current state
terraform show

# 2. Destroy specific resources
terraform destroy -target=azurerm_resource_group_template_deployment.aks_ipv6_dual_stack
terraform destroy -target=azurerm_resource_group_template_deployment.vnet_ipv6

# 3. Re-apply
terraform apply
```

#### Complete Teardown and Redeploy

```bash
# Full destroy (careful!)
terraform destroy

# Verify cleanup
az group list --query "[?contains(name,'<your-prefix>')].name" -o table

# Redeploy
terraform apply
```

### 12.4 Support Resources

- **Azure AKS IPv6 Documentation**: https://learn.microsoft.com/azure/aks/configure-kubenet-dual-stack
- **Kubernetes Dual-Stack**: https://kubernetes.io/docs/concepts/services-networking/dual-stack/
- **Terraform ARM Templates**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment
- **viya4-iac-azure Issues**: https://github.com/sassoftware/viya4-iac-azure/issues

---

# Appendix

## A. Subnet Calculation Examples

For VNet prefix `fd00:1234:5678::/48`:

| Subnet | CIDR | Usage | Calculated |
|--------|------|-------|------------|
| AKS | `fd00:1234:5678::/64` | Worker nodes | `cidrsubnet(prefix, 16, 0)` |
| Misc | `fd00:1234:5678:0:1::/64` | Infrastructure VMs | `cidrsubnet(prefix, 16, 1)` |
| Reserved | `fd00:1234:5678:0:2::/64` | Future use | `cidrsubnet(prefix, 16, 2)` |
| ... | ... | ... | Up to 65,536 /64 subnets |

## B. Glossary

| Term | Definition |
|------|------------|
| **Dual-Stack** | Network supporting both IPv4 and IPv6 simultaneously |
| **ULA** | Unique Local Address (fd00::/8) - IPv6 private range |
| **CNI Overlay** | Container Network Interface using encapsulation |
| **CIDR** | Classless Inter-Domain Routing notation |
| **ARM Template** | Azure Resource Manager deployment template (JSON) |
| **ipFamilyPolicy** | Kubernetes service IPv4/IPv6 behavior setting |
| **/48** | IPv6 prefix - 80 bits for host addresses (2^80 IPs) |
| **/64** | IPv6 subnet standard - 64 bits for hosts (2^64 IPs) |

## C. Quick Reference Commands

```bash
# Deployment
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Get credentials
az aks get-credentials -g <rg> -n <aks>

# Quick validation
kubectl get nodes -o wide
kubectl run test --image=nginx
kubectl get pod test -o jsonpath='{.status.podIPs[*].ip}'

# Service creation
kubectl create deployment app --image=nginx
kubectl expose deployment app --port=80
kubectl patch svc app -p '{"spec":{"ipFamilyPolicy":"PreferDualStack","ipFamilies":["IPv4","IPv6"]}}'
kubectl get svc app -o jsonpath='{.spec.clusterIPs[*]}'

# Cleanup test resources
kubectl delete pod test
kubectl delete deployment app
kubectl delete svc app
```
---

## Conclusion

The IPv6 dual-stack implementation for viya4-iac-azure provides production-ready networking for modern SAS Viya deployments. The solution seamlessly integrates with existing infrastructure while maintaining backward compatibility.
