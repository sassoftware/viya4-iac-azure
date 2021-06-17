# #aks
output "aks_host" {
  value = module.aks.host
}

output "nat_ip" {
  value = data.azurerm_public_ip.aks_public_ip.ip_address
}

output "kube_config" {
  value = module.kubeconfig.kube_config
}

output "aks_cluster_node_username" {
  value = module.aks.cluster_username
}

output "aks_cluster_password" {
  value = module.aks.cluster_password
  sensitive = true
}

#postgres
output "postgres_server_name" {
  value = var.create_postgres && var.create_postgresql_flexible_server ? azurerm_postgresql_flexible_server.flexpsql[0].name : var.create_postgres ? element(coalescelist(module.postgresql.*.server_name, [" "]), 0) : null
}
output "postgres_fqdn" {
  value = var.create_postgres && var.create_postgresql_flexible_server ? azurerm_postgresql_flexible_server.flexpsql[0].fqdn : var.create_postgres ? element(coalescelist(module.postgresql.*.server_fqdn, [" "]), 0) : null
}
output "postgres_admin" {
  value = var.create_postgres && var.create_postgresql_flexible_server ? "${element(coalescelist(azurerm_postgresql_flexible_server.flexpsql.*.administrator_login, [" "]), 0)}" : var.create_postgres ? "${element(coalescelist(module.postgresql.*.administrator_login, [" "]), 0)}@${element(coalescelist(module.postgresql.*.server_name, [" "]), 0)}" : null
}
output "postgres_password" {
  value     = var.create_postgres && var.create_postgresql_flexible_server ? element(coalescelist(azurerm_postgresql_flexible_server.flexpsql.*.administrator_password, [" "]), 0) : var.create_postgres ? element(coalescelist(module.postgresql.*.administrator_password, [" "]), 0) : null
  sensitive = true
}
output "postgres_server_id" {
  value = var.create_postgres && var.create_postgresql_flexible_server ? azurerm_postgresql_flexible_server.flexpsql[0].id : var.create_postgres ? element(coalescelist(module.postgresql.*.server_id, [" "]), 0) : null
}
output "postgres_server_port" {
  value = var.create_postgres ? "5432" : null
}

# jump server
output jump_private_ip {
  value = var.create_jump_vm ? element(coalescelist(module.jump.*.private_ip_address, [""]), 0) : null
}

output jump_public_ip {
  value = var.create_jump_vm && var.create_jump_public_ip ? element(coalescelist(module.jump.*.public_ip_address, [""]), 0) : null
}

output jump_admin_username {
  value = var.create_jump_vm ? element(coalescelist(module.jump.*.admin_username, [""]), 0) : null
}

output jump_rwx_filestore_path {
  value = var.create_jump_vm ? var.jump_rwx_filestore_path : null
}

# nfs server
output nfs_private_ip {
  value = var.storage_type == "standard" ? element(coalescelist(module.nfs.*.private_ip_address, [""]), 0) : null
}

output nfs_public_ip {
  value = var.storage_type == "standard" && var.create_nfs_public_ip ? element(coalescelist(module.nfs.*.public_ip_address, [""]), 0) : null
}

output nfs_admin_username {
  value = var.storage_type == "standard" ? element(coalescelist(module.nfs.*.admin_username, [""]), 0) : null
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
  sensitive = true
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
  value = var.storage_type == "ha" ? element(coalescelist(module.netapp.*.netapp_endpoint, [""]), 0) : element(coalescelist(module.nfs.*.private_ip_address, [""]), 0)
}

output "rwx_filestore_path" {
  value = var.storage_type == "ha" ? element(coalescelist(module.netapp.*.netapp_path, [""]), 0) : "/export"
}

output "rwx_filestore_config" {
  value = var.storage_type == "ha" ? jsonencode({
    "version" : 1,
    "storageDriverName" : "azure-netapp-files",
    "subscriptionID" : split("/", data.azurerm_subscription.current.id)[2],
    "tenantID" : data.azurerm_subscription.current.tenant_id,
    "clientID" : var.client_id,
    "clientSecret" : var.client_secret,
    "location" : module.resource_group.location,
    "serviceLevel" : var.netapp_service_level,
    "virtualNetwork" : module.vnet.name,
    "subnet" : module.vnet.subnets["netapp"],
    "defaults" : {
      "exportRule" : element(module.vnet.address_space, 0),
    }
  }) : null
}
