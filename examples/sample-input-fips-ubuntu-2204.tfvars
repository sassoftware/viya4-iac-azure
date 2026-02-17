# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Example configuration for FIPS-enabled cluster with Ubuntu Pro FIPS 22.04
# 
# IMPORTANT: To use Ubuntu 22.04 on AKS worker nodes, you MUST create a custom image.
# By default, AKS with fips_enabled=true uses Ubuntu 20.04 FIPS (Azure-managed).
# 
# This example shows how to configure the infrastructure to use a custom 
# Ubuntu Pro FIPS 22.04 image that you create in Azure Compute Gallery.
#
# See scripts/README.md for step-by-step instructions on creating the custom image.

# Authentication
subscription_id = "<your-subscription-id>"
tenant_id       = "<your-tenant-id>"

# General
prefix   = "fips2204"
location = "eastus"

# SSH
ssh_public_key = "~/.ssh/id_rsa.pub"

# AKS Cluster
kubernetes_version = "1.33"

# IMPORTANT: Accept marketplace image terms BEFORE creating your custom image:
# az vm image terms accept --urn Canonical:0001-com-ubuntu-pro-jammy-fips:pro-fips-22_04:latest --subscription <subscription-id>

# ====================================================================================
# FIPS Configuration - Two Options
# ====================================================================================
# 
# Option 1: Ubuntu 20.04 FIPS (DEFAULT - Azure-managed, automatic updates)
# -------------------------------------------------------------------------
# fips_enabled = true
# use_custom_image_for_fips = false  # (default)
# # AKS automatically uses Ubuntu 20.04 FIPS with automatic patching
#
# Option 2: Ubuntu 22.04 FIPS (CUSTOM IMAGE - requires manual maintenance)
# -------------------------------------------------------------------------
# 1. Create custom image using: ./scripts/create-fips-2204-image.sh
# 2. Copy the Image ID from script output
# 3. Configure as shown below:

fips_enabled = true
use_custom_image_for_fips = true
custom_node_source_image_id = "/subscriptions/<subscription-id>/resourceGroups/viya4-image-builder/providers/Microsoft.Compute/galleries/viya4ImageGallery/images/ubuntu-pro-fips-2204/versions/1.0.0"

# ====================================================================================

# Default Node Pool
default_nodepool_min_nodes = 2
default_nodepool_max_nodes = 5
default_nodepool_vm_type   = "Standard_E8s_v5"

# Additional Node Pools
node_pools = {
  cas = {
    machine_type = "Standard_E16s_v5"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 5
    max_pods     = 110
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels = {
      "workload.sas.com/class" = "cas"
    }
    linux_os_config = null
    community_priority = "Regular"
    community_eviction_policy = null
    community_spot_max_price = null
  }
  compute = {
    machine_type = "Standard_E16s_v5"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 5
    max_pods     = 110
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    linux_os_config = null
    community_priority = "Regular"
    community_eviction_policy = null
    community_spot_max_price = null
  }
  stateful = {
    machine_type = "Standard_E8s_v5"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    max_pods     = 110
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels = {
      "workload.sas.com/class" = "stateful"
    }
    linux_os_config = null
    community_priority = "Regular"
    community_eviction_policy = null
    community_spot_max_price = null
  }
  stateless = {
    machine_type = "Standard_E8s_v5"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 5
    max_pods     = 110
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels = {
      "workload.sas.com/class" = "stateless"
    }
    linux_os_config = null
    community_priority = "Regular"
    community_eviction_policy = null
    community_spot_max_price = null
  }
}

# Storage
storage_type = "standard"

# Jump Server and NFS
# Note: Jump and NFS VMs already use Ubuntu Pro FIPS 22.04 when fips_enabled = true
create_jump_vm    = true
create_nfs_public_ip = false
jump_vm_admin     = "jumpuser"
nfs_vm_admin      = "nfsuser"

# Container Registry
create_container_registry = true

# PostgreSQL
create_postgres_server = false

# Networking
vnet_address_space = "192.168.0.0/16"

# Tags
tags = {
  environment = "dev"
  project     = "viya4-fips-2204"
  owner       = "sas-admin"
  compliance  = "fips-140-2"
}
