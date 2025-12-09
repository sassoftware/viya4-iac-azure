# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# aks
output "aks_host" {
  value     = module.aks.host
  sensitive = true
}

output "nat_ip" {
  value = var.egress_public_ip_name == null ? module.aks.cluster_public_ip : data.azurerm_public_ip.nat-ip[0].ip_address
}

output "kube_config" {
  value     = module.kubeconfig.kube_config
  sensitive = true
}

output "aks_cluster_node_username" {
  value     = module.aks.cluster_username
  sensitive = true
}

output "aks_cluster_password" {
  value     = module.aks.cluster_password
  sensitive = true
}

output "aks_pod_cidr" {
  # If the aks_network_plugin is set to azure, use the aks subnet address space as the pod CIDR.
  value = (
    var.aks_network_plugin == "kubenet" ||
    (var.aks_network_plugin == "azure" && var.aks_network_plugin_mode == "overlay")
  ) ? var.aks_pod_cidr : module.vnet.subnets["aks"].address_prefixes[0]
}

# postgres

output "postgres_servers" {
  value     = length(module.flex_postgresql) != 0 ? local.postgres_outputs : null
  sensitive = true
}

# jump server
output "jump_private_ip" {
  value = var.create_jump_vm ? module.jump[0].private_ip_address : null
}

output "jump_public_ip" {
  value = var.create_jump_vm && var.create_jump_public_ip ? module.jump[0].public_ip_address : null
}

output "jump_admin_username" {
  value = var.create_jump_vm ? module.jump[0].admin_username : null
}

output "jump_rwx_filestore_path" {
  value = var.create_jump_vm ? var.jump_rwx_filestore_path : null
}

# nfs server
output "nfs_private_ip" {
  value = var.storage_type == "standard" ? module.nfs[0].private_ip_address : null
}

output "nfs_public_ip" {
  value = var.storage_type == "standard" && var.create_nfs_public_ip ? module.nfs[0].public_ip_address : null
}

output "nfs_admin_username" {
  value = var.storage_type == "standard" ? module.nfs[0].admin_username : null
}

# acr
output "cr_name" {
  value = var.create_container_registry ? element(coalescelist(azurerm_container_registry.acr[*].name, [" "]), 0) : null
}

output "cr_id" {
  value = var.create_container_registry ? element(coalescelist(azurerm_container_registry.acr[*].id, [" "]), 0) : null
}

output "cr_endpoint" {
  value = var.create_container_registry ? element(coalescelist(azurerm_container_registry.acr[*].login_server, [" "]), 0) : null
}

output "cr_admin_user" {
  value = (var.create_container_registry && var.container_registry_admin_enabled) ? element(coalescelist(azurerm_container_registry.acr[*].admin_username, [" "]), 0) : null
}

output "cr_admin_password" {
  value     = (var.create_container_registry && var.container_registry_admin_enabled) ? element(coalescelist(azurerm_container_registry.acr[*].admin_password, [" "]), 0) : null
  sensitive = true
}

output "location" {
  value = var.location
}

output "prefix" {
  value = var.prefix
}

output "cluster_name" {
  value = module.aks.name
}

output "provider_account" {
  value = data.azurerm_subscription.current.display_name
}

output "provider" {
  value = "azure"
}

output "rwx_filestore_endpoint" {
  value = (var.storage_type == "none"
    ? null
    : var.storage_type == "ha" ? module.netapp[0].netapp_endpoint : module.nfs[0].private_ip_address
  )
}

output "rwx_filestore_path" {
  value = (var.storage_type == "none"
    ? null
    : var.storage_type == "ha" ? module.netapp[0].netapp_path : "/export"
  )
}

output "rwx_filestore_config" {
  value = var.storage_type == "ha" ? jsonencode({
    "version" : 1,
    "storageDriverName" : "azure-netapp-files",
    "subscriptionID" : split("/", data.azurerm_subscription.current.id)[2],
    "tenantID" : data.azurerm_subscription.current.tenant_id,
    "clientID" : var.client_id,
    "clientSecret" : var.client_secret,
    "location" : local.aks_rg.location,
    "serviceLevel" : var.netapp_service_level,
    "virtualNetwork" : module.vnet.name,
    "subnet" : module.vnet.subnets["netapp"],
    "defaults" : {
      "exportRule" : element(tolist(module.vnet.address_space), 0),
    }
  }) : null
}

output "cluster_node_pool_mode" {
  value = var.cluster_node_pool_mode
}

output "cluster_api_mode" {
  value = var.cluster_api_mode
}

output "aks_network_plugin" {
  value = var.aks_network_plugin
}

output "application_gateway_id" {
  description = "Application Gateway ID"
  value       = var.create_app_gateway ? module.app_gateway[0].id : null
}

output "application_gateway_name" {
  description = "Application Gateway name"
  value       = var.create_app_gateway ? module.app_gateway[0].name : null
}

output "application_gateway_public_ip" {
  description = "Application Gateway public IP address"
  value       = var.create_app_gateway ? module.app_gateway[0].public_ip_address : null
}

output "application_gateway_identity_principal_id" {
  description = "Application Gateway identity principal ID"
  value       = var.create_app_gateway ? module.app_gateway[0].identity_principal_id : null
}
