# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "client_key" {
  value = var.rbac_aad_enabled ? azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key : azurerm_kubernetes_cluster.aks.kube_config[0].client_key
}

output "client_certificate" {
  value = var.rbac_aad_enabled ? azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate : azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
}

output "cluster_ca_certificate" {
  value = var.rbac_aad_enabled ? azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate : azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
}

output "cluster_username" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].username
}

output "cluster_password" {
  value = var.rbac_aad_enabled ? azurerm_kubernetes_cluster.aks.kube_admin_config[0].password : azurerm_kubernetes_cluster.aks.kube_config[0].password
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "host" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].host
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "cluster_public_ip" {
  value = var.cluster_egress_type == "loadBalancer" ? data.azurerm_public_ip.cluster_public_ip[0].ip_address : null
}

output "name" {
  value = azurerm_kubernetes_cluster.aks.name
}
