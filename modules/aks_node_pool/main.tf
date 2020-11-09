# Reference: https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster_node_pool.html

resource "azurerm_kubernetes_cluster_node_pool" "autoscale_node_pool" {
  count                 = var.enable_auto_scaling ? 1 : 0

  name                  = var.node_pool_name
  kubernetes_cluster_id = var.aks_cluster_id
  vnet_subnet_id        = var.vnet_subnet_id
  availability_zones    = var.availability_zones

  vm_size               = var.machine_type
  os_disk_size_gb       = var.os_disk_size

  enable_auto_scaling   = var.enable_auto_scaling
  node_count            = var.node_count
  max_count             = var.max_nodes
  min_count             = var.min_nodes

  node_labels           = var.node_labels
  node_taints           = var.node_taints

  tags                  = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "static_node_pool" {
  count                 = var.enable_auto_scaling ? 0 : 1

  name                  = var.node_pool_name
  kubernetes_cluster_id = var.aks_cluster_id
  vnet_subnet_id        = var.vnet_subnet_id
  availability_zones    = var.availability_zones

  vm_size               = var.machine_type
  os_disk_size_gb       = var.os_disk_size

  enable_auto_scaling   = var.enable_auto_scaling
  node_count            = var.node_count
  max_count             = var.max_nodes
  min_count             = var.min_nodes

  node_labels           = var.node_labels
  node_taints           = var.node_taints

  tags = var.tags
}
