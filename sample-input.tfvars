#!NOTE!# These are only a subset of inputs from variables.tf
# Customize this file to add any more inputs from 'variables.tf' file that you want to change 
# and change the values according to your need
prefix                          = "viya-tst1"
location                        = "eastus2"
#
# If you provide a public key this will be used for all vm's created
# If a public key is not provided as public_key will be generated along
# with it's private_key counter parts. This will also generated outpout
# for the articated associated with this key.
#
ssh_public_key                  = "~/.ssh/id_rsa.pub"
postgres_administrator_password = "GoSASViya4"

# AKS config
kubernetes_version                   = "1.18.8"
cluster_endpoint_public_access_cidrs = []
default_nodepool_node_count          = 2
default_nodepool_vm_type             = "Standard_D4_v2"
tags                                 = { "project_name" = "viya", "environment" = "test" }

# AKS Node Pools config
create_cas_nodepool       = true
cas_nodepool_node_count   = 1
cas_nodepool_min_nodes    = 1
cas_nodepool_auto_scaling = true
cas_nodepool_vm_type      = "Standard_E16s_v3"

create_compute_nodepool       = true
compute_nodepool_node_count   = 1
compute_nodepool_min_nodes    = 1
compute_nodepool_auto_scaling = true
compute_nodepool_vm_type      = "Standard_E16s_v3"

create_connect_nodepool       = true
connect_nodepool_node_count   = 1
connect_nodepool_min_nodes    = 1
connect_nodepool_auto_scaling = true
connect_nodepool_vm_type      = "Standard_E16s_v3"

create_stateless_nodepool       = true
stateless_nodepool_node_count   = 2
stateless_nodepool_min_nodes    = 2
stateless_nodepool_auto_scaling = true
stateless_nodepool_vm_type      = "Standard_D16s_v3"

create_stateful_nodepool       = true
stateful_nodepool_node_count   = 3
stateful_nodepool_min_nodes    = 3
stateful_nodepool_auto_scaling = true
stateful_nodepool_vm_type      = "Standard_D16s_v3"

# Jump Box
create_jump_public_ip          = true
jump_vm_admin                  = "jumpuser"

# Storage for Viya Compute Services
storage_type = "standard"
# Supported storage_type values
#    "dev"    - AzureDisk/AzureFiles in Dev/Test environment
#    "standard" - Custom managed NFS Server VM and disks
#    "ha"     - Azure NetApp Files managed service

# required ONLY when storage_type = standard, for NFS Server VM
create_nfs_public_ip  = false
nfs_vm_admin          = "nfsuser"
nfs_raid_disk_size    = 64
# required ONLY when storage_type = ha for Azure NetApp Files service
netapp_service_level = "Premium"
netapp_size_in_tb    = 4

# Azure Postgres values config
create_postgres                  = true # set this to "false" when using internal Crunchy Postgres and Azure Postgres is NOT needed
postgres_ssl_enforcement_enabled = false

# Azure Container Registry
create_container_registry           = false
container_registry_sku              = "Standard"
container_registry_admin_enabled    = "false"
container_registry_geo_replica_locs = null
