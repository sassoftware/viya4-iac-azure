# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Reference: https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster_node_pool.html

resource "azurerm_kubernetes_cluster_node_pool" "autoscale_node_pool" {
  count                        = var.auto_scaling_enabled ? 1 : 0
  name                         = var.node_pool_name
  kubernetes_cluster_id        = var.aks_cluster_id
  vnet_subnet_id               = var.vnet_subnet_id
  zones                        = var.zones
  fips_enabled                 = var.fips_enabled
  host_encryption_enabled      = var.host_encryption_enabled
  proximity_placement_group_id = var.proximity_placement_group_id == "" ? null : var.proximity_placement_group_id
  vm_size                      = var.machine_type
  os_disk_size_gb              = var.os_disk_size
  os_type                      = var.os_type
  auto_scaling_enabled         = var.auto_scaling_enabled
  node_public_ip_enabled       = var.node_public_ip_enabled
  node_count                   = var.node_count
  max_count                    = var.max_nodes
  min_count                    = var.min_nodes
  max_pods                     = var.max_pods
  node_labels                  = var.node_labels
  node_taints                  = var.node_taints
  orchestrator_version         = var.orchestrator_version
  tags                         = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "static_node_pool" {
  count                        = var.auto_scaling_enabled ? 0 : 1
  name                         = var.node_pool_name
  kubernetes_cluster_id        = var.aks_cluster_id
  vnet_subnet_id               = var.vnet_subnet_id
  zones                        = var.zones
  fips_enabled                 = var.fips_enabled
  host_encryption_enabled      = var.host_encryption_enabled
  proximity_placement_group_id = var.proximity_placement_group_id == "" ? null : var.proximity_placement_group_id
  vm_size                      = var.machine_type
  os_disk_size_gb              = var.os_disk_size
  os_type                      = var.os_type
  auto_scaling_enabled         = var.auto_scaling_enabled
  node_count                   = var.node_count
  max_count                    = var.max_nodes
  min_count                    = var.min_nodes
  max_pods                     = var.max_pods
  node_labels                  = var.node_labels
  node_taints                  = var.node_taints
  orchestrator_version         = var.orchestrator_version
  tags                         = var.tags
}
