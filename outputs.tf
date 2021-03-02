# #aks
output "aks_host" {
  value = module.aks.host
}

output "nat_ip" {
  value = data.azurerm_public_ip.aks_public_ip.ip_address
}

output "kube_config" {
  value = module.aks.kube_config
}

output "aks_cluster_node_username" {
  value = module.aks.cluster_username
}

output "aks_cluster_password" {
  value = module.aks.cluster_password
}

#postgres
output "postgres_server_name" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.server_name, [" "]), 0) : null
}
output "postgres_fqdn" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.server_fqdn, [" "]), 0) : null
}
output "postgres_admin" {
  value = var.create_postgres ? "${element(coalescelist(module.postgresql.*.administrator_login, [" "]), 0)}@${element(coalescelist(module.postgresql.*.server_name, [" "]), 0)}" : null
}
output "postgres_password" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.administrator_password, [" "]), 0) : null
}
output "postgres_server_id" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.server_id, [" "]), 0) : null
}
output "postgres_server_port" {
  value = var.create_postgres ? "5432" : null
}

# jump server
output jump_private_ip {
  value = var.create_jump_vm ? module.jump.private_ip_address : null
}

output jump_public_ip {
  value = var.create_jump_vm && var.create_jump_public_ip ? module.jump.public_ip_address : null
}

output jump_admin_username {
  value = var.create_jump_vm ? module.jump.admin_username : null
}

output jump_rwx_filestore_path {
  value = var.create_jump_vm ? var.jump_rwx_filestore_path : null
}

# nfs server
output nfs_private_ip {
  value = var.storage_type == "standard" ? module.nfs.private_ip_address : null
}

output nfs_public_ip {
  value = var.storage_type == "standard" && var.create_nfs_public_ip ? module.nfs.public_ip_address : null
}

output nfs_admin_username {
  value = var.storage_type == "standard" ? module.nfs.admin_username : null
}

# acr
output "cr_name" {
  value = var.create_container_registry ? element(coalescelist(azurerm_container_registry.acr.*.name, [" "]), 0) : null
}

output "cr_id" {
  value = var.create_container_registry ? element(coalescelist(azurerm_container_registry.acr.*.id, [" "]), 0) : null
}

output "cr_endpoint" {
  value = var.create_container_registry ? element(coalescelist(azurerm_container_registry.acr.*.login_server, [" "]), 0) : null
}

output "cr_admin_user" {
  value = (var.create_container_registry && var.container_registry_admin_enabled) ? element(coalescelist(azurerm_container_registry.acr.*.admin_username, [" "]), 0) : null
}

output "cr_admin_password" {
  value = (var.create_container_registry && var.container_registry_admin_enabled) ? element(coalescelist(azurerm_container_registry.acr.*.admin_password, [" "]), 0) : null
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
  value = var.storage_type == "ha" ? module.netapp.netapp_endpoint : module.nfs.private_ip_address
}

output "rwx_filestore_path" {
  value = var.storage_type == "ha" ? module.netapp.netapp_path : "/export"
}

output "rwx_filestore_config" {
  value = var.storage_type == "ha" ? jsonencode({
    "version" : 1,
    "storageDriverName" : "azure-netapp-files",
    "subscriptionID" : split("/", data.azurerm_subscription.current.id)[2],
    "tenantID" : data.azurerm_subscription.current.tenant_id,
    "clientID" : var.client_id,
    "clientSecret" : var.client_secret,
    "location" : azurerm_resource_group.azure_rg.location,
    "serviceLevel" : var.netapp_service_level,
    "virtualNetwork" : module.vnet.vnet_name,
    "subnet" : module.netapp.netapp_subnet,
    "defaults" : {
      "exportRule" : local.vnet_cidr_block,
    }
  }) : null
}
