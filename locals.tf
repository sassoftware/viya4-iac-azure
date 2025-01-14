# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

locals {

  # Useful flags
  ssh_public_key = (var.create_jump_vm || var.storage_type == "standard"
    ? can(file(var.ssh_public_key)) ? file(var.ssh_public_key) : var.ssh_public_key != null ? length(var.ssh_public_key) > 0 ? var.ssh_public_key : null : null
    : null
  )

  # CIDR/Network
  default_public_access_cidrs          = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  vm_public_access_cidrs               = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  acr_public_access_cidrs              = var.acr_public_access_cidrs == null ? local.default_public_access_cidrs : var.acr_public_access_cidrs
  cluster_endpoint_public_access_cidrs = var.cluster_api_mode == "private" ? [] : (var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs)
  postgres_public_access_cidrs         = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs

  subnets = { for k, v in var.subnets : k => v if !(k == "netapp" && var.storage_type == "standard") }

  # Kubernetes
  kubeconfig_filename = "${var.prefix}-aks-kubeconfig.conf"
  kubeconfig_path     = var.iac_tooling == "docker" ? "/workspace/${local.kubeconfig_filename}" : local.kubeconfig_filename

  # PostgreSQL
  default_postgres_configuration = [{ name : "max_prepared_transactions", value : 1024 }, { name : "azure.extensions", value : "PLPGSQL,PGCRYPTO" }]
  postgres_servers               = var.postgres_servers == null ? {} : { for k, v in var.postgres_servers : k => merge(var.postgres_server_defaults, v, ) }
  postgres_firewall_rules        = [for addr in local.postgres_public_access_cidrs : { "name" : replace(replace(addr, "/", "_"), ".", "_"), "start_ip" : cidrhost(addr, 0), "end_ip" : cidrhost(addr, abs(pow(2, 32 - split("/", addr)[1]) - 1)) }]

  postgres_outputs = length(module.flex_postgresql) != 0 ? { for k, v in module.flex_postgresql :
    k => {
      "server_name" : module.flex_postgresql[k].server_name,
      "fqdn" : module.flex_postgresql[k].server_fqdn,
      "admin" : module.flex_postgresql[k].administrator_login,
      "password" : module.flex_postgresql[k].administrator_password,
      "server_port" : "5432",
      "ssl_enforcement_enabled" : local.postgres_servers[k].ssl_enforcement_enabled,
      "internal" : false
    }
  } : {}

  # Container Registry
  container_registry_sku = title(var.container_registry_sku)

  aks_rg = (var.resource_group_name == null
    ? azurerm_resource_group.aks_rg[0]
    : data.azurerm_resource_group.aks_rg[0]
  )

  network_rg = (var.vnet_resource_group_name == null
    ? local.aks_rg
    : data.azurerm_resource_group.network_rg[0]
  )

  nsg         = var.nsg_name == null ? azurerm_network_security_group.nsg[0] : data.azurerm_network_security_group.nsg[0]
  nsg_rg_name = local.network_rg.name

  # Use BYO UAI if given, else create a UAI
  aks_uai_id = (var.aks_identity == "uai"
    ? (var.aks_uai_name == null
      ? azurerm_user_assigned_identity.uai[0].id
      : data.azurerm_user_assigned_identity.uai[0].id
    )
    : null
  )

  aks_uai_principal_id = (var.aks_identity == "uai"
    ? (var.aks_uai_name == null
      ? azurerm_user_assigned_identity.uai[0].principal_id
      : data.azurerm_user_assigned_identity.uai[0].principal_id
    )
    : null
  )


  cluster_egress_type = (var.cluster_egress_type == null
    ? (var.egress_public_ip_name == null
      ? "loadBalancer"
      : "userDefinedRouting"
    )
    : var.cluster_egress_type
  )
}

