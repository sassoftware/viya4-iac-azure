# Reference: https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster_node_pool.html

resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
  count                 = var.create_node_pool ? 1 : 0

  name                  = var.node_pool_name
  kubernetes_cluster_id = var.aks_cluster_id
  vnet_subnet_id        = var.vnet_subnet_id
  availability_zones    = var.availability_zones

  vm_size         = var.machine_type
  os_disk_size_gb = var.os_disk_size

  enable_auto_scaling = var.enable_auto_scaling
  node_count          = var.node_count
  max_count           = var.max_nodes
  min_count           = var.min_nodes

  #### bug(?) with Azure's node pool resource in terraform.  these are all doced but terraform (v 0.12.24) throwing errors.   
  node_labels           = var.node_labels
  node_taints           = var.node_taints

  tags                  = var.tags
}
