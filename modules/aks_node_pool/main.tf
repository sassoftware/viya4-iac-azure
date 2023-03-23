# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Reference: https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster_node_pool.html

resource "azurerm_kubernetes_cluster_node_pool" "autoscale_node_pool" {
  count                        = var.enable_auto_scaling ? 1 : 0
  name                         = var.node_pool_name
  kubernetes_cluster_id        = var.aks_cluster_id
  vnet_subnet_id               = var.vnet_subnet_id
  zones                        = var.zones
  fips_enabled                 = var.fips_enabled
  proximity_placement_group_id = var.proximity_placement_group_id == "" ? null : var.proximity_placement_group_id
  vm_size                      = var.machine_type
  os_disk_size_gb              = var.os_disk_size
  # TODO: enable after azurerm v2.37.0
  # os_disk_type                 = var.os_disk_type
  os_type             = var.os_type
  enable_auto_scaling = var.enable_auto_scaling
  # Still in preview, revisit if needed later - https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools#assign-a-public-ip-per-node-for-your-node-pools-preview
  # enable_node_public_ip        = var.enable_node_public_ip
  node_count           = var.node_count
  max_count            = var.max_nodes
  min_count            = var.min_nodes
  max_pods             = var.max_pods
  node_labels          = var.node_labels
  node_taints          = var.node_taints
  orchestrator_version = var.orchestrator_version
  tags                 = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "static_node_pool" {
  count                        = var.enable_auto_scaling ? 0 : 1
  name                         = var.node_pool_name
  kubernetes_cluster_id        = var.aks_cluster_id
  vnet_subnet_id               = var.vnet_subnet_id
  zones                        = var.zones
  fips_enabled                 = var.fips_enabled
  proximity_placement_group_id = var.proximity_placement_group_id == "" ? null : var.proximity_placement_group_id
  vm_size                      = var.machine_type
  os_disk_size_gb              = var.os_disk_size
  # TODO: enable after azurerm v2.37.0
  # os_disk_type                 = var.os_disk_type
  os_type              = var.os_type
  enable_auto_scaling  = var.enable_auto_scaling
  node_count           = var.node_count
  max_count            = var.max_nodes
  min_count            = var.min_nodes
  max_pods             = var.max_pods
  node_labels          = var.node_labels
  node_taints          = var.node_taints
  orchestrator_version = var.orchestrator_version
  tags                 = var.tags
}
