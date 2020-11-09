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

output "cluster_slb_ip_id" {
  # effective_outbound_ips is a set of strings, that needs to be converted to a list type
  value = tolist(azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0]
}

output "name" {
  value = azurerm_kubernetes_cluster.aks.name
}
