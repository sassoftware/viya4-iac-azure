output "client_key" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.client_key
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
}

output "cluster_username" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.username
}

output "cluster_password" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.password
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "host" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.host
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "cluster_public_ip" {
  value = azurerm_kubernetes_cluster.aks.private_cluster_enabled ? null : data.azurerm_public_ip.cluster_public_ip.*.ip_address
}

output "name" {
  value = azurerm_kubernetes_cluster.aks.name
}
