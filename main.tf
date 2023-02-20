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
  host                   = var.rbac_aad_managed ? module.aks.admin_host : module.aks.host
  client_key             = var.rbac_aad_managed ? base64decode(module.aks.admin_client_key) : base64decode(module.aks.client_key)
  client_certificate     = var.rbac_aad_managed ? base64decode(module.aks.admin_client_certificate) : base64decode(module.aks.client_certificate)
  cluster_ca_certificate = var.rbac_aad_managed ? base64decode(module.aks.admin_cluster_ca_certificate) : base64decode(module.aks.cluster_ca_certificate)
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
  resource_group_name = local.aks_rg.name
  tags                = var.tags
}

data "azurerm_network_security_group" "nsg" {
  count               = var.nsg_name == null ? 0 : 1
  name                = var.nsg_name
  resource_group_name = local.network_rg.name
}

module "vnet" {
  source = "./modules/azurerm_vnet"

  name                = var.vnet_name
  prefix              = var.prefix
  resource_group_name = local.network_rg.name
  location            = var.location
  subnets             = local.subnets
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

## https://registry.terraform.io/modules/Azure/aks/azurerm/latest
module "aks" {
  source                                      = "Azure/aks/azurerm"
  version                                     = "6.6.0"
  cluster_name                                = local.cluster_name
  resource_group_name                         = local.aks_rg.name
  prefix                                      = var.prefix
  location                                    = var.location
  sku_tier                                    = var.aks_cluster_sku_tier
  ## FIPS is not available in 6.6.0 version yet. Uncomment below once available.
  # fips_enabled                                = var.fips_enabled
  http_application_routing_enabled            = false
  agents_pool_name                            = "system"
  enable_auto_scaling                         = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? false : true
  agents_count                                = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? var.default_nodepool_min_nodes : null
  agents_min_count                            = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? null : var.default_nodepool_min_nodes
  agents_max_count                            = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? null : var.default_nodepool_max_nodes
  agents_max_pods                             = var.default_nodepool_max_pods
  os_disk_size_gb                             = var.default_nodepool_os_disk_size
  os_disk_type                                = var.default_os_disk_type
  agents_size                                 = var.default_nodepool_vm_type
  admin_username                              = var.node_vm_admin
  public_ssh_key                              = try(file(var.ssh_public_key), "")
  vnet_subnet_id                              = module.vnet.subnets["aks"].id
  kubernetes_version                          = var.kubernetes_version
  orchestrator_version                        = var.kubernetes_version
  api_server_authorized_ip_ranges             = var.cluster_api_mode == "private" ? [] : local.cluster_endpoint_public_access_cidrs ## Private cluster cannot be enabled with AuthorizedIPRanges.
  agents_availability_zones                   = var.default_nodepool_availability_zones
  network_plugin                              = var.aks_network_plugin
  network_policy                              = var.aks_network_plugin == "azure" ? var.aks_network_policy : null
  net_profile_dns_service_ip                  = var.aks_dns_service_ip
  net_profile_docker_bridge_cidr              = var.aks_docker_bridge_cidr
  net_profile_pod_cidr                        = var.aks_network_plugin == "kubenet" ? var.aks_pod_cidr : null
  net_profile_service_cidr                    = var.aks_service_cidr
  net_profile_outbound_type                   = var.cluster_egress_type
  load_balancer_sku                           = "standard"
  enable_node_public_ip                       = false
  tags                                        = var.tags
  identity_ids                                = local.aks_uai_id
  identity_type                               = var.aks_identity == "uai" ? "UserAssigned" : "SystemAssigned"
  client_id                                   = local.aks_uai_id == null ? var.client_id : ""
  client_secret                               = local.aks_uai_id == null ? var.client_secret : ""
  role_based_access_control_enabled           = var.role_based_access_control_enabled
  rbac_aad_managed                            = var.rbac_aad_managed
  rbac_aad                                    = var.rbac_aad_managed ? true : false
  rbac_aad_azure_rbac_enabled                 = var.azure_rbac_enabled
  rbac_aad_admin_group_object_ids             = var.rbac_aad_admin_group_object_ids
  rbac_aad_tenant_id                          = var.rbac_aad_tenant_id
  private_cluster_enabled                     = local.aks_private_cluster
  private_dns_zone_id                         = local.aks_private_cluster ? var.aks_private_dns_zone_id : null
  log_analytics_workspace_enabled             = var.create_aks_azure_monitor
  log_analytics_workspace                     = var.log_analytics_workspace
  log_analytics_workspace_resource_group_name = var.log_analytics_workspace_resource_group_name
  log_analytics_workspace_sku                 = var.log_analytics_workspace_sku
  log_retention_in_days                       = var.log_retention_in_days

  depends_on = [module.vnet]
}

data "azurerm_lb" "aks_lb" {
  count               = var.cluster_egress_type == "loadBalancer" ? 1 : 0
  name                = "kubernetes"
  resource_group_name = module.aks.node_resource_group
  depends_on          = [module.aks]
}

data "azurerm_public_ip" "cluster_public_ip" {
  count               = var.cluster_egress_type == "loadBalancer" ? 1 : 0
  name                = reverse(split("/", data.azurerm_lb.aks_lb.0.frontend_ip_configuration.0.public_ip_address_id))[0]
  resource_group_name = module.aks.node_resource_group
  depends_on          = [module.aks]
}

module "kubeconfig" {
  source                   = "./modules/kubeconfig"
  prefix                   = var.prefix
  create_static_kubeconfig = var.create_static_kubeconfig
  path                     = local.kubeconfig_path
  namespace                = "kube-system"
  cluster_name             = local.cluster_name
  endpoint                 = var.rbac_aad_managed ? module.aks.admin_host : module.aks.host
  ca_crt                   = var.rbac_aad_managed ? module.aks.admin_cluster_ca_certificate : module.aks.cluster_ca_certificate
  client_crt               = var.rbac_aad_managed ? module.aks.admin_client_certificate : module.aks.client_certificate
  client_key               = var.rbac_aad_managed ? module.aks.admin_client_key : module.aks.client_key
  token                    = var.rbac_aad_managed ? module.aks.admin_password : module.aks.password
  depends_on               = [module.aks]
}

module "node_pools" {
  source = "./modules/aks_node_pool"

  for_each = var.node_pools

  node_pool_name               = each.key
  aks_cluster_id               = module.aks.aks_id
  vnet_subnet_id               = module.vnet.subnets["aks"].id
  machine_type                 = each.value.machine_type
  os_disk_size                 = each.value.os_disk_size
  os_disk_type                 = each.value.os_disk_type
  fips_enabled                 = var.fips_enabled
  enable_auto_scaling          = each.value.min_nodes == each.value.max_nodes ? false : true
  node_count                   = each.value.min_nodes
  min_nodes                    = each.value.min_nodes == each.value.max_nodes ? null : each.value.min_nodes
  max_nodes                    = each.value.min_nodes == each.value.max_nodes ? null : each.value.max_nodes
  max_pods                     = each.value.max_pods == null ? 110 : each.value.max_pods
  node_taints                  = each.value.node_taints
  node_labels                  = each.value.node_labels
  zones                        = (var.node_pools_availability_zone == "" || var.node_pools_proximity_placement == true) ? [] : (var.node_pools_availability_zones != null) ? var.node_pools_availability_zones : [var.node_pools_availability_zone]
  proximity_placement_group_id = element(coalescelist(azurerm_proximity_placement_group.proximity.*.id, [""]), 0)
  orchestrator_version         = var.kubernetes_version
  tags                         = var.tags
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
  vnet_name           = module.vnet.name
  subnet_id           = module.vnet.subnets["netapp"].id
  network_features    = var.netapp_network_features
  service_level       = var.netapp_service_level
  size_in_tb          = var.netapp_size_in_tb
  protocols           = var.netapp_protocols
  volume_path         = "${var.prefix}-${var.netapp_volume_path}"
  tags                = var.tags
  allowed_clients     = concat(module.vnet.subnets["aks"].address_prefixes, module.vnet.subnets["misc"].address_prefixes)
  depends_on          = [module.vnet]
}

data "external" "git_hash" {
  program = ["files/tools/iac_git_info.sh"]
}

data "external" "iac_tooling_version" {
  program = ["files/tools/iac_tooling_version.sh"]
}

resource "kubernetes_config_map" "sas_iac_buildinfo" {
  metadata {
    name      = "sas-iac-buildinfo"
    namespace = "kube-system"
  }

  data = {
    git-hash    = lookup(data.external.git_hash.result, "git-hash")
    iac-tooling = var.iac_tooling
    terraform   = <<EOT
version: ${lookup(data.external.iac_tooling_version.result, "terraform_version")}
revision: ${lookup(data.external.iac_tooling_version.result, "terraform_revision")}
provider-selections: ${lookup(data.external.iac_tooling_version.result, "provider_selections")}
outdated: ${lookup(data.external.iac_tooling_version.result, "terraform_outdated")}
EOT
  }

  depends_on = [module.aks]
}

## Enable Azure monitor diagnostic settings if and only if create_aks_azure_monitor is true
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting

resource "azurerm_monitor_diagnostic_setting" "audit" {
  count = var.create_aks_azure_monitor ? 1 : 0

  name                       = "${var.prefix}-monitor_diagnostic_setting"
  target_resource_id         = module.aks.aks_id
  log_analytics_workspace_id = module.aks.azurerm_log_analytics_workspace_id

  dynamic "log" {
    iterator = log_category
    for_each = var.resource_log_category

    content {
      category = log_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = var.log_retention_in_days
      }
    }
  }

  dynamic "metric" {
    iterator = metric_category
    for_each = var.metric_category

    content {
      category = metric_category.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = var.log_retention_in_days
      }
    }
  }

  depends_on = [module.aks]
}
