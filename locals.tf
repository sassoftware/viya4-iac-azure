locals {
  is_private = var.infra_mode == "private" ? true : false
  is_standard = var.infra_mode == "standard" ? true : false

  default_public_access_cidrs          = local.is_private ? [] : (var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs)
  vm_public_access_cidrs               = local.is_private ? [] : (var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs)
  acr_public_access_cidrs              = local.is_private ? [] : (var.acr_public_access_cidrs == null ? local.default_public_access_cidrs : var.acr_public_access_cidrs)
  cluster_endpoint_public_access_cidrs = local.is_private ? [] : (var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs)
  postgres_public_access_cidrs         = local.is_private ? [] : (var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs)

  create_jump_public_ip = var.create_jump_public_ip == null ? local.is_standard : var.create_jump_public_ip
  create_nfs_public_ip = var.create_nfs_public_ip == null ? local.is_standard : var.create_nfs_public_ip

  postgres_firewall_rules              = [for addr in local.postgres_public_access_cidrs : { "name" : replace(replace(addr, "/", "_"), ".", "_"), "start_ip" : cidrhost(addr, 0), "end_ip" : cidrhost(addr, abs(pow(2, 32 - split("/", addr)[1]) - 1)) }]

  subnets = { for k, v in var.subnets : k => v if ! ( k == "netapp" && var.storage_type == "standard")}
  container_registry_sku = title(var.container_registry_sku)

  kubeconfig_filename = "${var.prefix}-aks-kubeconfig.conf"
  kubeconfig_path     = var.iac_tooling == "docker" ? "/workspace/${local.kubeconfig_filename}" : local.kubeconfig_filename
}
