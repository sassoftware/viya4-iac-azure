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
  value = var.create_postgres ? module.postgresql.postgres_server_name : null
}
output "postgres_fqdn" {
  value = var.create_postgres ? module.postgresql.postgres_server_fqdn : null
}
output "postgres_admin" {
  value = var.create_postgres ? "${module.postgresql.postgres_administrator_login}@${module.postgresql.postgres_server_name}" : null
}
output "postgres_password" {
  value = var.create_postgres ? module.postgresql.postgres_administrator_password : null
}
output "postgres_server_id" {
  value = var.create_postgres ? module.postgresql.postgres_server_id : null
}
output "postgres_server_port" {
  value = var.create_postgres ? "5432" : null
}

# jump server
output jump_private_ip {
  value = local.create_jump_vm ? module.jump.private_ip_address : null
}

output jump_public_ip {
  value = local.create_jump_vm && var.create_jump_public_ip ? module.jump.public_ip_address : null
}

output jump_admin_username {
  value = local.create_jump_vm ? module.jump.admin_username : null
}

output jump_private_key_pem {
  value = local.create_jump_vm ? module.jump.private_key_pem : null
}

output jump_public_key_pem {
  value = local.create_jump_vm ? module.jump.public_key_pem : null
}

output jump_public_key_openssh {
  value = local.create_jump_vm ? module.jump.public_key_openssh : null
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

output nfs_private_key_pem {
  value = var.storage_type != "dev" ? module.nfs.private_key_pem : null
}

output nfs_public_key_pem {
  value = var.storage_type != "dev" ? module.nfs.public_key_pem : null
}

output nfs_public_key_openssh {
  value = var.storage_type != "dev" ? module.nfs.public_key_openssh : null
}

output aks_private_key_pem {
  value = var.storage_type != "dev" ? module.aks.private_key_pem : null
}

# acr
output "acr_id" {
  value = module.acr.acr_id
}

output "acr_url" {
  value = module.acr.acr_login_server
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
  value = var.storage_type != "dev" ? coalesce(module.netapp.netapp_endpoint, module.nfs.private_ip_address, "") : null
}

output "rwx_filestore_path" {
  value = var.storage_type != "dev" ? coalesce(module.netapp.netapp_path, "/export") : null
}

output "rwx_filestore_config" {
  value = var.storage_type == "ha" ? jsonencode({
    "version" : 1,
    "storageDriverName" : "azure-netapp-files",
    "subscriptionID" : split("/", data.azurerm_subscription.current.id)[2],
    "tenantID" : "${data.azurerm_subscription.current.tenant_id}",
    "clientID" : "${var.client_id}",
    "clientSecret" : "${var.client_secret}",
    "location" : "${module.azure_rg.location}",
    "serviceLevel" : "${var.netapp_service_level}",
    "virtualNetwork" : "${azurerm_virtual_network.vnet.name}",
    "subnet" : "${module.netapp.netapp_subnet}",
    "defaults" : {
      "exportRule" : "${local.vnet_cidr_block}",
    }
  }) : null
}
