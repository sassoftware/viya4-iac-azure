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
4. [Implementation Details](#4-implementation-details)
5. [Code Changes Summary](#5-code-changes-summary)
6. [Known Limitations](#6-known-limitations)

### Part 2: Deployment Guide
7. [Prerequisites](#7-prerequisites)
8. [Configuration](#8-configuration)
9. [Deployment Steps](#9-deployment-steps)
10. [Post-Deployment Setup](#10-post-deployment-setup)

### Part 3: Validation and Operations
11. [Infrastructure Validation](#11-infrastructure-validation)
12. [Cluster Validation](#12-cluster-validation)
13. [Workload Validation](#13-workload-validation)
14. [Troubleshooting](#14-troubleshooting)
15. [Future Enhancements](#15-future-enhancements)

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
- IPv4: `10.244.0.0/16` (65,536 addresses) - Hardcoded
- IPv6: `fd00:10:244::/64` (2^64 addresses) - Default, user-configurable
- Uses Unique Local Addresses (ULA) to avoid VNet conflicts

**Service CIDR - Cluster service IPs**:
- IPv4: `10.0.0.0/16` (65,536 addresses) - Hardcoded
- IPv6: `fd00:10:0::/108` (2^20 addresses) - Default, user-configurable
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
- Process: Open Azure support ticket

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

## 4. Implementation Details

### 4.1 Key Components Modified

#### New Variables Added (`variables.tf`)

```terraform
variable "enable_ipv6" {
  description = "Enable IPv6 dual-stack support"
  type        = bool
  default     = false
}

variable "vnet_ipv6_address_space" {
  description = "IPv6 address space for VNet (/48 CIDR)"
  type        = string
  default     = "fd00:1234:5678::/48"  # ULA range - production-safe for internal use
  # For internet-facing clusters, use Azure-assigned or org-allocated prefix
}

variable "aks_pod_ipv6_cidr" {
  description = "IPv6 CIDR for pod overlay network"
  type        = string
  default     = "fd00:10:244::/64"  # ULA range - suitable for production
}

variable "aks_service_ipv6_cidr" {
  description = "IPv6 CIDR for services"
  type        = string
  default     = "fd00:10:0::/108"  # ULA range - suitable for production
}
```

#### Local Calculations (`locals.tf`)

Auto-calculated subnet ranges from VNet /48:

```terraform
locals {
  # Calculate /64 subnets from /48 VNet space
  ipv6_aks_subnet_cidr  = var.enable_ipv6 ? cidrsubnet(var.vnet_ipv6_address_space, 16, 0) : null
  ipv6_misc_subnet_cidr = var.enable_ipv6 ? cidrsubnet(var.vnet_ipv6_address_space, 16, 1) : null
}
```

**Calculation Logic**:
- Input: `/48` VNet space (e.g., `fd00:1234:5678::/48`)
- Operation: `cidrsubnet(space, 16, index)` creates `/64` subnets
- Result: 
  - Index 0 -> `fd00:1234:5678::/64` (AKS subnet)
  - Index 1 -> `fd00:1234:5678:0:1::/64` (Misc subnet)

### 4.2 VNet Creation

**Conditional VNet Module** (skipped when IPv6 enabled):
```terraform
module "vnet" {
  source = "./modules/azurerm_vnet"
  count  = var.enable_ipv6 ? 0 : 1  # Skip if IPv6 enabled
  # ... IPv4-only configuration
}
```

**IPv6 VNet via ARM Template** (`main.tf`):

```terraform
resource "azurerm_resource_group_template_deployment" "vnet_ipv6" {
  count = var.enable_ipv6 ? 1 : 0
  name  = "${var.prefix}-vnet-ipv6"
  
  template_content = jsonencode({
    resources = [{
      type       = "Microsoft.Network/virtualNetworks"
      apiVersion = "2023-04-01"
      properties = {
        addressSpace = {
          addressPrefixes = [
            var.vnet_address_space,        # IPv4
            var.vnet_ipv6_address_space    # IPv6
          ]
        }
        subnets = [
          {
            name = "${var.prefix}-aks-subnet"
            properties = {
              addressPrefixes = [
                var.subnets["aks"].prefixes[0],  # IPv4
                local.ipv6_aks_subnet_cidr       # IPv6
              ]
            }
          },
          {
            name = "${var.prefix}-misc-subnet"
            properties = {
              addressPrefixes = [
                var.subnets["misc"].prefixes[0], # IPv4
                local.ipv6_misc_subnet_cidr      # IPv6
              ]
            }
          }
        ]
      }
    }]
  })
}
```

**Why ARM Template?**
- Azure Terraform provider doesn't support dual-stack subnet configuration natively
- ARM templates provide access to latest Azure API features
- Incremental deployment mode allows safe updates

### 4.3 AKS Cluster Configuration

**IPv6 Dual-Stack Patch** (`main.tf`):

```terraform
resource "azurerm_resource_group_template_deployment" "aks_ipv6_dual_stack" {
  count = var.enable_ipv6 ? 1 : 0
  name  = "${var.prefix}-aks-ipv6-patch"
  
  template_content = jsonencode({
    resources = [{
      type       = "Microsoft.ContainerService/managedClusters"
      apiVersion = "2023-07-01"
      properties = {
        networkProfile = {
          ipFamilies     = ["IPv4", "IPv6"]
          ipFamilyPolicy = "RequireDualStack"
          podCidrs = [
            "10.244.0.0/16",           # IPv4 (hardcoded)
            var.aks_pod_ipv6_cidr      # IPv6 (configurable)
          ]
          serviceCidrs = [
            "10.0.0.0/16",             # IPv4 (hardcoded)
            var.aks_service_ipv6_cidr  # IPv6 (configurable)
          ]
          loadBalancerProfile = {
            managedOutboundIPs = {
              count     = 1  # IPv4 outbound IP
              countIPv6 = 1  # IPv6 outbound IP
            }
          }
        }
      }
    }]
  })
  
  depends_on = [
    module.aks,
    module.node_pools  # Critical: wait for all node pools
  ]
}
```

**Why Post-Creation Patch?**
- Terraform azurerm provider doesn't support `ipFamilies` and `podCidrs` array natively
- ARM template can update existing cluster with dual-stack configuration
- `depends_on` prevents race conditions with node pool creation

### 4.4 Network Security Rules

```terraform
resource "azurerm_network_security_rule" "ipv6_lb_outbound" {
  name        = "SAS-IPv6-LB-Outbound"
  count       = var.enable_ipv6 ? 1 : 0
  priority    = 190
  direction   = "Outbound"
  access      = "Allow"
  protocol    = "*"
  source_address_prefix      = "::/0"  # All IPv6
  destination_address_prefix = "::/0"  # All IPv6
}
```

---

## 5. Code Changes Summary

### 5.1 Files Modified

| File | Changes | Lines | Purpose |
|------|---------|-------|---------|
| `variables.tf` | Added 4 IPv6 variables | ~50 | Configuration inputs |
| `locals.tf` | Subnet calculation logic | ~5 | Auto-calculate IPv6 subnets |
| `main.tf` | Major networking changes | ~200 | Core IPv6 implementation |
| `modules/azure_aks/main.tf` | Comments & passthrough | ~20 | Module integration |
| `modules/azure_aks/variables.tf` | IPv6 variable declarations | ~20 | Module interface |
| `examples/sample-input-ipv6.tfvars` | New sample file | ~90 | User guidance |

### 5.2 New Resources Created

1. **`azurerm_resource_group_template_deployment.vnet_ipv6`**
   - Creates dual-stack VNet and subnets
   - Conditional: Only when `enable_ipv6 = true`

2. **`azurerm_resource_group_template_deployment.aks_ipv6_dual_stack`**
   - Configures AKS cluster for dual-stack
   - Conditional: Only when `enable_ipv6 = true`
   - Critical dependency on node pools completion

3. **`azurerm_network_security_rule.ipv6_lb_outbound`**
   - Allows IPv6 outbound traffic
   - Conditional: Only when `enable_ipv6 = true`

4. **Data Sources**: `aks_ipv6`, `misc_ipv6`
   - Reference ARM-created resources in Terraform
   - Conditional: Only when `enable_ipv6 = true`

### 5.3 Deployment Flow

```
User sets enable_ipv6 = true
        |
        v
1. Create IPv4 resources (RG, NSG, UAI)
        |
        v
2. ARM Template: Create dual-stack VNet
        |
        v
3. Data sources fetch VNet/subnet info
        |
        v
4. Deploy AKS cluster (IPv4 only initially)
        |
        v
5. Deploy all node pools
        |
        v
6. ARM Template: Patch AKS to dual-stack
        |
        v
7. Complete deployment (dual-stack active)
```

---

## 6. Known Limitations

### 6.1 Infrastructure Components (IPv4 Only)

| Component | IPv4 | IPv6 | Reason |
|-----------|------|------|--------|
| Jump VM | YES | NO | Azure VMs don't auto-enable IPv6 on dual-stack subnets |
| NFS VM | YES | NO | Same as Jump VM |
| PostgreSQL Flexible Server | YES | NO | Azure service limitation |
| Azure NetApp Files | YES | NO | Azure service limitation |
| Container Registry | YES | NO | Azure service limitation |

**Impact**: Infrastructure components accessible via IPv4 only. Kubernetes workloads unaffected.

### 6.2 Hardcoded IPv4 Values

In ARM template (`main.tf` lines 474-476):
```terraform
podCidrs = [
  "10.244.0.0/16",          # Hardcoded IPv4
  var.aks_pod_ipv6_cidr     # Configurable IPv6
]
serviceCidrs = [
  "10.0.0.0/16",            # Hardcoded IPv4
  var.aks_service_ipv6_cidr # Configurable IPv6
]
```

**Impact**: IPv4 pod/service CIDRs not customizable in IPv6 mode.  
**Future Enhancement**: Add `aks_pod_cidr` and `aks_service_cidr` variables.

### 6.3 Default Kubernetes Service

**Observation**: `kubernetes.default.svc` remains IPv4-only.  
**Reason**: Created before IPv6 configuration applied.  
**Impact**: None - expected behavior, doesn't affect operations.

### 6.4 External IPv6 Connectivity

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

---

# Part 2: Deployment Guide

## 7. Prerequisites

### 7.1 Prerequisites Checklist

- [ ] Azure subscription with AKS permissions
- [ ] Terraform >= 1.0 installed
- [ ] Azure CLI >= 2.40 (optional, for validation)
- [ ] kubectl >= 1.21 (for testing)
- [ ] **IPv6 address prefix planned**:
  - [ ] For **production with internet access**: Obtain IPv6 prefix from Azure support
  - [ ] For **production internal-only**: Use default ULA `fd00:1234:5678::/48` or generate unique prefix
  - [ ] For **testing/examples only**: Can use `2001:db8::/48` (NOT for production)

### 7.2 Required Azure Permissions

- Microsoft.ContainerService/* (for AKS)
- Microsoft.Network/* (for VNet, subnets, NSG)
- Microsoft.Resources/deployments/* (for ARM templates)
- Microsoft.Authorization/roleAssignments/write (for UAI)

### 7.3 Network Planning

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

### 8.3 Complete Configuration Template

Copy and customize `examples/sample-input-ipv6.tfvars`:

```bash
cd viya4-iac-azure
cp examples/sample-input-ipv6.tfvars terraform.tfvars
vim terraform.tfvars
```

Required customizations:
- `prefix`: Unique identifier for your resources
- `location`: Azure region
- `default_public_access_cidrs`: Your IP ranges for access
- `ssh_public_key`: Path to your SSH public key
- `tags`: Your organizational tags

---

## 9. Deployment Steps

### 9.1 Initialize Terraform

```bash
cd viya4-iac-azure

# Initialize Terraform (download providers)
terraform init

# Optional: Validate configuration
terraform validate
```

### 9.2 Plan Deployment

```bash
# Create execution plan
terraform plan -out=tfplan

# Review the plan carefully for these resources:
# - azurerm_resource_group_template_deployment.vnet_ipv6
# - azurerm_resource_group_template_deployment.aks_ipv6_dual_stack
# - data.azurerm_subnet.aks_ipv6
# - data.azurerm_subnet.misc_ipv6
# - azurerm_network_security_rule.ipv6_lb_outbound
```

**Expected Changes**:
- ~100-150 resources to create
- 2 ARM template deployments (VNet + AKS patch)
- Several data sources for IPv6 resources
- NSG rule for IPv6 egress

### 9.3 Deploy Infrastructure

```bash
# Apply the plan
terraform apply tfplan

# Deployment typically takes 20-30 minutes:
# - VNet creation: 2-3 minutes
# - AKS cluster: 10-15 minutes
# - Node pools: 6-8 minutes
# - IPv6 patch: 5-10 minutes
```

**Monitoring Progress**:
```bash
# In another terminal, monitor ARM deployments
az deployment group list \
  --resource-group <your-rg-name> \
  --query "[?properties.provisioningState=='Running'].{name:name,state:properties.provisioningState}" \
  --output table
```

### 9.4 Handle Common Deployment Issues

#### Issue: Resource Group Already Exists
```bash
# If previous deployment failed, destroy and retry
terraform destroy -target=azurerm_resource_group.network_rg
terraform apply tfplan
```

#### Issue: Node Pool Operation in Progress
```
Error: Operation not allowed because there's an in progress create node pool operation
```
**Solution**: Wait 5-10 minutes for operation to complete, then:
```bash
terraform apply tfplan
```

#### Issue: IPv6 Patch Fails
**Solution**: Already handled via `depends_on` in code. If error persists:
```bash
# Check node pools are complete
az aks nodepool list -g <rg> --cluster-name <cluster> --query "[].provisioningState"

# Should all show "Succeeded"
# Then re-apply
terraform apply
```

---

## 10. Post-Deployment Setup

### 10.1 Get Cluster Credentials

```bash
# Method 1: Using Terraform output
terraform output kube_config > ~/.kube/config-viya-ipv6
export KUBECONFIG=~/.kube/config-viya-ipv6

# Method 2: Using Azure CLI
az aks get-credentials \
  --resource-group <your-rg-name> \
  --name <your-prefix>-aks \
  --overwrite-existing

# Verify access
kubectl cluster-info
kubectl get nodes
```

### 10.2 Quick Health Check

```bash
# Check nodes have dual-stack IPs
kubectl get nodes -o wide

# Expected: Each node shows both IPv4 and IPv6 addresses
```

### 10.3 Set Up Access

```bash
# If using Jump VM, SSH into it
JUMP_IP=$(terraform output jump_public_ip | tr -d '"')
ssh jumpuser@$JUMP_IP

# From Jump VM, access AKS
az aks get-credentials --resource-group <rg> --name <aks>
kubectl get nodes
```

---

# Part 3: Validation and Operations

## 11. Infrastructure Validation

### 11.1 Verify Virtual Network

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

### 11.2 Verify Subnets

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

### 11.3 Verify Network Security Group

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

## 12. Cluster Validation

### 12.1 Verify AKS Network Profile

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

### 12.2 Verify Node IP Addresses

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

## 13. Workload Validation

### 13.1 Deploy Test Pod

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

### 13.2 Test Pod-to-Pod IPv6 Connectivity

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

### 13.3 Create and Test Dual-Stack Service

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

### 13.4 Test Service Connectivity

> **Prerequisite**: Service must exist (complete section 13.3 first)

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

### 13.5 Verify System Pods

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

### 13.6 Automated Validation Script

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

## 14. Troubleshooting

### 14.1 Common Deployment Issues

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

### 14.2 Debugging Commands

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

### 14.3 Recovery Procedures

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

### 14.4 Support Resources

- **Azure AKS IPv6 Documentation**: https://learn.microsoft.com/azure/aks/configure-kubenet-dual-stack
- **Kubernetes Dual-Stack**: https://kubernetes.io/docs/concepts/services-networking/dual-stack/
- **Terraform ARM Templates**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment
- **viya4-iac-azure Issues**: https://github.com/sassoftware/viya4-iac-azure/issues

---

## 15. Future Enhancements

### 15.1 Short-Term (Next Release)

1. **Parameterize IPv4 CIDRs**
   - Make `10.244.0.0/16` and `10.0.0.0/16` configurable
   - Add `aks_pod_cidr` and `aks_service_cidr` variables

2. **Enhanced Validation**
   - Add Terraform `validation` blocks for CIDR overlap detection
   - Pre-deployment checks for common misconfigurations

3. **Automated Testing**
   - Add IPv6 CI/CD test cases
   - Automated validation after deployment

### 15.2 Medium-Term (Future Releases)

1. **Infrastructure VM IPv6 Support**
   - Enable IPv6 on Jump VM NICs
   - Configure IPv6 on NFS VM
   - Document manual setup process

2. **LoadBalancer Services**
   - Example dual-stack LoadBalancer configurations
   - Ingress controller IPv6 examples

3. **Multi-Region Support**
   - Test IPv6 in all Azure regions
   - Document region-specific limitations

### 15.3 Long-Term (Exploration)

1. **Native Provider Support**
   - Migrate from ARM templates when azurerm adds full support
   - Simplify codebase

2. **Advanced Networking**
   - IPv6 Network Policies
   - Service Mesh dual-stack support

3. **IPv6-Only Mode**
   - Single-stack IPv6 deployments (no IPv4)
   - Requires platform validation

---

## Appendix

### A. Reference Architecture Comparison

#### IPv4-Only (Standard)
```
VNet: 192.168.0.0/16
├─ AKS Subnet: 192.168.0.0/23
├─ Misc Subnet: 192.168.2.0/24
└─ NetApp Subnet: 192.168.3.0/24

Pods: 10.244.0.0/16 (overlay)
Services: 10.0.0.0/16
```

#### IPv6 Dual-Stack (New)
```
VNet: 192.168.0.0/16 + fd00:abcd:1234::/48 (or assigned prefix)
├─ AKS Subnet: 192.168.0.0/23 + fd00:abcd:1234::/64
└─ Misc Subnet: 192.168.2.0/24 + fd00:abcd:1234:0:1::/64

Pods: 10.244.0.0/16 + fd00:10:244::/64 (overlay)
Services: 10.0.0.0/16 + fd00:10:0::/108
```

### B. Subnet Calculation Examples

For VNet prefix `fd00:1234:5678::/48`:

| Subnet | CIDR | Usage | Calculated |
|--------|------|-------|------------|
| AKS | `fd00:1234:5678::/64` | Worker nodes | `cidrsubnet(prefix, 16, 0)` |
| Misc | `fd00:1234:5678:0:1::/64` | Infrastructure VMs | `cidrsubnet(prefix, 16, 1)` |
| Reserved | `fd00:1234:5678:0:2::/64` | Future use | `cidrsubnet(prefix, 16, 2)` |
| ... | ... | ... | Up to 65,536 /64 subnets |

### C. Glossary

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

### D. Quick Reference Commands

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

### E. Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Jan 2026 | Initial IPv6 dual-stack implementation |
| | | - ARM templates for VNet and AKS |
| | | - Auto-subnet calculation |
| | | - ULA defaults (production-safe) |
| | | - Comprehensive documentation |

---

## Conclusion

The IPv6 dual-stack implementation for viya4-iac-azure provides production-ready networking for modern SAS Viya deployments. The solution seamlessly integrates with existing infrastructure while maintaining backward compatibility.

**Key Achievements**:
- Full dual-stack networking for AKS clusters
- Production-safe ULA defaults
- Comprehensive validation procedures
- Backward compatible (IPv4-only remains default)
- Validated on 6-node production cluster

**Business Value**:
- Enables IPv6-required customer environments
- Future-proofs infrastructure
- Demonstrates technical leadership
- Provides competitive advantage

---

**Document Version**: 1.0  
**Last Updated**: January 19, 2026  
**Author**: Abhishek Kumar  
**Contact**: abhishek.kumar@sas.com  
**JIRA**: PSCLOUD-409
