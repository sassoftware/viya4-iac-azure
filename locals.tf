locals {
  
  # Useful flags
  is_private            = var.infra_mode == "private" ? true : false
  is_standard           = var.infra_mode == "standard" ? true : false
  create_jump_public_ip = var.create_jump_public_ip == null ? local.is_standard : var.create_jump_public_ip
  create_nfs_public_ip  = var.create_nfs_public_ip == null ? local.is_standard : var.create_nfs_public_ip

  # CIDR/Network
  default_public_access_cidrs          = local.is_private ? [] : (var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs)
  vm_public_access_cidrs               = local.is_private ? [] : (var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs)
  acr_public_access_cidrs              = local.is_private ? [] : (var.acr_public_access_cidrs == null ? local.default_public_access_cidrs : var.acr_public_access_cidrs)
  cluster_endpoint_public_access_cidrs = local.is_private ? [] : (var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs)
  postgres_public_access_cidrs         = local.is_private ? [] : (var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs)
  subnets = { for k, v in var.subnets : k => v if ! ( k == "netapp" && var.storage_type == "standard")}

  # Kubernetes
  cluster_name = "${var.prefix}-aks"
  kubeconfig_filename = "${var.prefix}-aks-kubeconfig.conf"
  kubeconfig_path     = var.iac_tooling == "docker" ? "/workspace/${local.kubeconfig_filename}" : local.kubeconfig_filename

  # PostgreSQL
  postgres_servers        = var.postgres_servers == null ? {} : { for k, v in var.postgres_servers : k => merge( var.postgres_server_defaults, v, )}
  postgres_firewall_rules = [for addr in local.postgres_public_access_cidrs : { "name" : replace(replace(addr, "/", "_"), ".", "_"), "start_ip" : cidrhost(addr, 0), "end_ip" : cidrhost(addr, abs(pow(2, 32 - split("/", addr)[1]) - 1)) }]

  postgres_outputs = length(module.postgresql) != 0 ? { for k,v in module.postgresql :
    k => {
      "server_name" : module.postgresql[k].server_name,
      "fqdn" : module.postgresql[k].server_fqdn,
      "admin" : "${module.postgresql[k].administrator_login}@${module.postgresql[k].server_name}",
      "password" : module.postgresql[k].administrator_password,
      "server_port" : "5432", # TODO - Create a var when supported
      "ssl_enforcement_enabled" : local.postgres_servers[k].ssl_enforcement_enabled,
      "internal" : false
    }
  } : {}

  # Container Registry
  container_registry_sku = title(var.container_registry_sku)

  aks_rg = ( var.resource_group_name == null
             ? azurerm_resource_group.aks_rg.0
             : data.azurerm_resource_group.aks_rg.0
           )

  network_rg = ( var.vnet_resource_group_name == null
                 ? local.aks_rg
                 : data.azurerm_resource_group.network_rg.0
               )

  nsg         = var.nsg_name == null ? azurerm_network_security_group.nsg.0 : data.azurerm_network_security_group.nsg.0
  nsg_rg_name = var.nsg_name == null ? local.aks_rg.name : local.network_rg.name

  # Use BYO UAI if given, else create a UAI
  aks_uai_id = ( var.aks_identity == "uai" 
                 ? ( var.aks_uai_name == null
                     ? azurerm_user_assigned_identity.uai.0.id
                     : data.azurerm_user_assigned_identity.uai.0.id
                   )
                 : null
               )
}

