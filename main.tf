# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## Azure-AKS
#
# Terraform Registry : https://registry.terraform.io/namespaces/Azure
# GitHub Repository  : https://github.com/terraform-azurerm-modules
#
provider "azurerm" {

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  partner_id      = var.partner_id
  use_msi         = var.use_msi

  features {}
}

provider "azuread" {
  client_id     = var.client_id
  client_secret = var.client_secret
  tenant_id     = var.tenant_id
}

provider "kubernetes" {
  host                   = module.aks.host
  client_key             = base64decode(module.aks.client_key)
  client_certificate     = base64decode(module.aks.client_certificate)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "network_rg" {
  count = var.vnet_resource_group_name == null ? 0 : 1
  name  = var.vnet_resource_group_name
}

resource "azurerm_resource_group" "aks_rg" {
  count    = var.resource_group_name == null ? 1 : 0
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "aks_rg" {
  count = var.resource_group_name == null ? 0 : 1
  name  = var.resource_group_name
}

resource "azurerm_proximity_placement_group" "proximity" {
  count = var.node_pools_proximity_placement ? 1 : 0

  name                = "${var.prefix}-ProximityPlacementGroup"
  location            = var.location
  resource_group_name = local.aks_rg.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  count               = var.nsg_name == null ? 1 : 0
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = local.network_rg.name
  tags                = var.tags
}

data "azurerm_network_security_group" "nsg" {
  count               = var.nsg_name == null ? 0 : 1
  name                = var.nsg_name
  resource_group_name = local.network_rg.name
}

data "azurerm_public_ip" "nat-ip" {
  count               = var.egress_public_ip_name == null ? 0 : 1
  name                = var.egress_public_ip_name
  resource_group_name = local.network_rg.name
}

module "vnet" {
  source = "./modules/azurerm_vnet"

  name                = var.vnet_name
  prefix              = var.prefix
  resource_group_name = local.network_rg.name
  location            = var.location
  subnets             = local.subnets
  roles               = var.msi_network_roles
  aks_uai_principal_id = local.aks_uai_principal_id
  add_uai_permissions = (var.aks_uai_name == null)
  existing_subnets    = var.subnet_names
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

resource "azurerm_container_registry" "acr" {
  count               = var.create_container_registry ? 1 : 0
  name                = join("", regexall("[a-zA-Z0-9]+", "${var.prefix}acr")) # alpha numeric characters only are allowed
  resource_group_name = local.aks_rg.name
  location            = var.location
  sku                 = local.container_registry_sku
  admin_enabled       = var.container_registry_admin_enabled

  dynamic "georeplications" {
    for_each = (local.container_registry_sku == "Premium" && var.container_registry_geo_replica_locs != null) ? toset(
    var.container_registry_geo_replica_locs) : []
    content {
      location = georeplications.key
      tags     = var.tags
    }
  }
  tags = var.tags
}

resource "azurerm_network_security_rule" "acr" {
  name                        = "SAS-ACR"
  description                 = "Allow ACR from source"
  count                       = (length(local.acr_public_access_cidrs) != 0 && var.create_container_registry) ? 1 : 0
  priority                    = 180
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5000"
  source_address_prefixes     = local.acr_public_access_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = local.nsg_rg_name
  network_security_group_name = local.nsg.name
}

module "aks" {
  source = "./modules/azure_aks"

  aks_cluster_name                         = "${var.prefix}-aks"
  aks_cluster_rg                           = local.aks_rg.name
  aks_cluster_dns_prefix                   = "${var.prefix}-aks"
  aks_cluster_sku_tier                     = var.aks_cluster_sku_tier
  aks_cluster_location                     = var.location
  node_resource_group_name                 = var.node_resource_group_name != "" ? var.node_resource_group_name : "MC_${local.aks_rg.name}_${var.prefix}-aks_${var.location}"
  cluster_support_tier                     = var.cluster_support_tier
  fips_enabled                             = var.fips_enabled
  aks_cluster_node_auto_scaling            = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? false : true
  aks_cluster_node_count                   = var.default_nodepool_min_nodes
  aks_cluster_min_nodes                    = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? null : var.default_nodepool_min_nodes
  aks_cluster_max_nodes                    = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? null : var.default_nodepool_max_nodes
  aks_cluster_max_pods                     = var.default_nodepool_max_pods
  aks_cluster_os_disk_size                 = var.default_nodepool_os_disk_size
  aks_cluster_node_vm_size                 = var.default_nodepool_vm_type
  aks_cluster_enable_host_encryption       = var.aks_cluster_enable_host_encryption
  aks_node_disk_encryption_set_id          = var.aks_node_disk_encryption_set_id
  aks_cluster_node_admin                   = var.node_vm_admin
  aks_cluster_run_command_enabled          = var.aks_cluster_run_command_enabled
  aks_cluster_ssh_public_key               = try(file(var.ssh_public_key), "")
  aks_cluster_private_dns_zone_id          = var.aks_cluster_private_dns_zone_id
  aks_vnet_subnet_id                       = module.vnet.subnets["aks"].id
  kubernetes_version                       = var.kubernetes_version
  aks_cluster_endpoint_public_access_cidrs = var.cluster_api_mode == "private" ? [] : local.cluster_endpoint_public_access_cidrs # "Private cluster cannot be enabled with AuthorizedIPRanges.""
  aks_availability_zones                   = var.default_nodepool_availability_zones
  aks_oms_enabled                          = var.create_aks_azure_monitor
  aks_log_analytics_workspace_id           = var.create_aks_azure_monitor ? azurerm_log_analytics_workspace.viya4[0].id : null
  aks_network_plugin                       = var.aks_network_plugin
  aks_network_policy                       = var.aks_network_policy
  aks_network_plugin_mode                  = var.aks_network_plugin_mode
  aks_dns_service_ip                       = var.aks_dns_service_ip
  cluster_egress_type                      = local.cluster_egress_type
  aks_pod_cidr                             = var.aks_pod_cidr
  aks_service_cidr                         = var.aks_service_cidr
  aks_cluster_tags                         = var.tags
  aks_uai_id                               = local.aks_uai_id
  client_id                                = var.client_id
  client_secret                            = var.client_secret
  rbac_aad_tenant_id                       = var.rbac_aad_tenant_id == null ? var.tenant_id != "" ? var.tenant_id : null : var.rbac_aad_tenant_id
  rbac_aad_enabled                         = var.rbac_aad_enabled
  rbac_aad_azure_rbac_enabled              = var.rbac_aad_azure_rbac_enabled
  rbac_aad_admin_group_object_ids          = var.rbac_aad_admin_group_object_ids
  aks_private_cluster                      = var.cluster_api_mode == "private" ? true : false
  depends_on                               = [module.vnet]
  aks_azure_policy_enabled                 = var.aks_azure_policy_enabled ? var.aks_azure_policy_enabled : false
  community_node_os_upgrade_channel        = var.community_node_os_upgrade_channel
  enable_workload_identity                 = var.enable_workload_identity
}

module "kubeconfig" {
  source                   = "./modules/kubeconfig"
  prefix                   = var.prefix
  create_static_kubeconfig = var.create_static_kubeconfig
  path                     = local.kubeconfig_path
  namespace                = "kube-system"
  cluster_name             = module.aks.name
  endpoint                 = module.aks.host
  ca_crt                   = module.aks.cluster_ca_certificate
  client_crt               = module.aks.client_certificate
  client_key               = module.aks.client_key
  token                    = module.aks.cluster_password
  depends_on               = [module.aks]
}

module "node_pools" {
  source = "./modules/aks_node_pool"

  for_each = var.node_pools

  node_pool_name               = each.key
  aks_cluster_id               = module.aks.cluster_id
  vnet_subnet_id               = module.vnet.subnets["aks"].id
  machine_type                 = each.value.machine_type
  fips_enabled                 = var.fips_enabled
  os_disk_size                 = each.value.os_disk_size
  auto_scaling_enabled         = each.value.min_nodes == each.value.max_nodes ? false : true
  node_count                   = each.value.min_nodes
  min_nodes                    = each.value.min_nodes == each.value.max_nodes ? null : each.value.min_nodes
  max_nodes                    = each.value.min_nodes == each.value.max_nodes ? null : each.value.max_nodes
  max_pods                     = each.value.max_pods == null ? 110 : each.value.max_pods
  node_taints                  = each.value.node_taints
  node_labels                  = each.value.node_labels
  zones                        = (var.node_pools_availability_zone == "" || var.node_pools_proximity_placement == true) ? [] : (var.node_pools_availability_zones != null) ? var.node_pools_availability_zones : [var.node_pools_availability_zone]
  proximity_placement_group_id = element(coalescelist(azurerm_proximity_placement_group.proximity[*].id, [""]), 0)
  orchestrator_version         = var.kubernetes_version
  host_encryption_enabled      = var.aks_cluster_enable_host_encryption
  tags                         = var.tags
  linux_os_config              = each.value.linux_os_config
  community_priority           = each.value.community_priority 
  community_eviction_policy    = each.value.community_eviction_policy
  community_spot_max_price     = each.value.community_spot_max_price

}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server
module "flex_postgresql" {
  source = "./modules/azurerm_postgresql_flex"

  for_each = local.postgres_servers != null ? length(local.postgres_servers) != 0 ? local.postgres_servers : {} : {}

  resource_group_name          = local.aks_rg.name
  location                     = var.location
  server_name                  = lower("${var.prefix}-${each.key}") # suffix '-flexpsql' added in the module
  sku_name                     = each.value.sku_name
  storage_mb                   = each.value.storage_mb
  backup_retention_days        = each.value.backup_retention_days
  geo_redundant_backup_enabled = each.value.geo_redundant_backup_enabled
  administrator_login          = each.value.administrator_login
  administrator_password       = each.value.administrator_password
  server_version               = each.value.server_version
  firewall_rule_prefix         = "${var.prefix}-${each.key}-postgres-firewall-"
  firewall_rules               = local.postgres_firewall_rules
  connectivity_method          = each.value.connectivity_method
  virtual_network_id           = each.value.connectivity_method == "private" ? module.vnet.id : null
  delegated_subnet_id          = each.value.connectivity_method == "private" ? module.vnet.subnets["postgresql"].id : null
  postgresql_configurations = each.value.ssl_enforcement_enabled ? concat(each.value.postgresql_configurations, local.default_postgres_configuration) : concat(
  each.value.postgresql_configurations, [{ name : "require_secure_transport", value : "OFF" }], local.default_postgres_configuration)
  tags = var.tags
}

module "netapp" {
  source = "./modules/azurerm_netapp"
  count  = var.storage_type == "ha" ? 1 : 0

  prefix              = var.prefix
  resource_group_name = local.aks_rg.name
  location            = var.location
  subnet_id           = module.vnet.subnets["netapp"].id
  network_features    = var.netapp_network_features
  service_level       = var.netapp_service_level
  size_in_tb          = var.netapp_size_in_tb
  protocols           = var.netapp_protocols
  volume_path         = "${var.prefix}-${var.netapp_volume_path}"
  tags                = var.tags
  allowed_clients     = concat(module.vnet.subnets["aks"].address_prefixes, module.vnet.subnets["misc"].address_prefixes)
  depends_on          = [module.vnet]

  community_netapp_volume_size = var.community_netapp_volume_size
  community_netapp_volume_zone = var.node_pools_availability_zone != "" ? tonumber(var.node_pools_availability_zone) : var.community_netapp_volume_zone
}

data "external" "git_hash" {
  program = ["${path.module}/files/tools/iac_git_info.sh"]
}

data "external" "iac_tooling_version" {
  program = ["${path.module}/files/tools/iac_tooling_version.sh"]
}

resource "kubernetes_config_map" "sas_iac_buildinfo" {
  metadata {
    name      = "sas-iac-buildinfo"
    namespace = "kube-system"
  }

  data = {
    git-hash    = data.external.git_hash.result["git-hash"]
    iac-tooling = var.iac_tooling
    terraform   = <<EOT
version: ${data.external.iac_tooling_version.result["terraform_version"]}
revision: ${data.external.iac_tooling_version.result["terraform_revision"]}
provider-selections: ${data.external.iac_tooling_version.result["provider_selections"]}
outdated: ${data.external.iac_tooling_version.result["terraform_outdated"]}
EOT
  }

  depends_on = [module.aks]
}
