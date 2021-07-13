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

locals {
  # CIDRs 
  default_public_access_cidrs          = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  vm_public_access_cidrs               = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  acr_public_access_cidrs              = var.acr_public_access_cidrs == null ? local.default_public_access_cidrs : var.acr_public_access_cidrs
  cluster_endpoint_cidrs               = var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs
  cluster_endpoint_public_access_cidrs = length(local.cluster_endpoint_cidrs) == 0 ? ["0.0.0.0/32"] : local.cluster_endpoint_cidrs
  postgres_public_access_cidrs         = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs
  postgres_firewall_rules              = [for addr in local.postgres_public_access_cidrs : { "name" : replace(replace(addr, "/", "_"), ".", "_"), "start_ip" : cidrhost(addr, 0), "end_ip" : cidrhost(addr, abs(pow(2, 32 - split("/", addr)[1]) - 1)) }]

  kubeconfig_filename = "${var.prefix}-aks-kubeconfig.conf"
  kubeconfig_path     = var.iac_tooling == "docker" ? "/workspace/${local.kubeconfig_filename}" : local.kubeconfig_filename

  subnets = { for k, v in var.subnets : k => v if ! ( k == "netapp" && var.storage_type == "standard")}

  container_registry_sku = title(var.container_registry_sku)
}

module "resource_group" {
  source   = "./modules/azurerm_resource_group"
  prefix   = var.prefix
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_proximity_placement_group" "proximity" {
  count = var.node_pools_proximity_placement ? 1 : 0

  name                = "${var.prefix}-ProximityPlacementGroup"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = module.resource_group.tags
  depends_on          = [module.resource_group]
}

module "nsg" {
  source              = "./modules/azurerm_network_security_group"
  prefix              = var.prefix
  name                = var.nsg_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = module.resource_group.tags
  depends_on          = [module.resource_group]
}

module "vnet" {
  source = "./modules/azurerm_vnet"

  name                = var.vnet_name
  prefix              = var.prefix
  resource_group_name = module.resource_group.name
  location            = var.location
  subnets             = local.subnets
  existing_subnets    = var.subnet_names
  address_space       = [var.vnet_address_space]
  tags                = module.resource_group.tags
  depends_on          = [module.resource_group]
}

data "template_file" "jump-cloudconfig" {
  template = file("${path.module}/files/cloud-init/jump/cloud-config")
  vars = {
    nfs_rwx_filestore_endpoint = var.storage_type == "ha" ? module.netapp.0.netapp_endpoint : module.nfs.0.private_ip_address
    nfs_rwx_filestore_path     = var.storage_type == "ha" ? module.netapp.0.netapp_path : "/export"
    jump_rwx_filestore_path    = var.jump_rwx_filestore_path
    vm_admin                   = var.jump_vm_admin
  }
}

data "template_cloudinit_config" "jump" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.jump-cloudconfig.rendered
  }
}

module "jump" {
  source            = "./modules/azurerm_vm"

  count             = var.create_jump_vm ? 1 : 0
  name              = "${var.prefix}-jump"
  azure_rg_name     = module.resource_group.name
  azure_rg_location = var.location
  vnet_subnet_id    = module.vnet.subnets["misc"].id
  machine_type      = var.jump_vm_machine_type
  azure_nsg_id      = module.nsg.id
  tags              = module.resource_group.tags
  vm_admin          = var.jump_vm_admin
  vm_zone           = var.jump_vm_zone
  ssh_public_key    = file(var.ssh_public_key)
  cloud_init        = data.template_cloudinit_config.jump.rendered
  create_public_ip  = var.create_jump_public_ip

  # Jump VM mounts NFS path hence dependency on 'module.nfs'
  depends_on = [module.vnet, module.nfs]
}

data "template_file" "nfs-cloudconfig" {
  template = file("${path.module}/files/cloud-init/nfs/cloud-config")
  vars = {
    base_cidr_block = element(module.vnet.address_space, 0)
    vm_admin        = var.nfs_vm_admin
  }
}

data "template_cloudinit_config" "nfs" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.nfs-cloudconfig.rendered
  }
}

module "nfs" {
  source                         = "./modules/azurerm_vm"

  count                          = var.storage_type == "standard" ? 1 : 0
  name                           = "${var.prefix}-nfs"
  azure_rg_name                  = module.resource_group.name
  azure_rg_location              = var.location
  proximity_placement_group_id   = element(coalescelist(azurerm_proximity_placement_group.proximity.*.id, [""]), 0)
  vnet_subnet_id                 = module.vnet.subnets["misc"].id
  machine_type                   = var.nfs_vm_machine_type
  azure_nsg_id                   = module.nsg.id
  tags                           = module.resource_group.tags
  vm_admin                       = var.nfs_vm_admin
  vm_zone                        = var.nfs_vm_zone
  ssh_public_key                 = file(var.ssh_public_key)
  cloud_init                     = data.template_cloudinit_config.nfs.rendered
  create_public_ip               = var.create_nfs_public_ip
  data_disk_count                = 4
  data_disk_size                 = var.nfs_raid_disk_size
  data_disk_storage_account_type = var.nfs_raid_disk_type
  data_disk_zones                = var.nfs_raid_disk_zones
  depends_on                     = [module.vnet]
}

resource "azurerm_network_security_rule" "vm-ssh" {
  name                        = "${var.prefix}-ssh"
  description                 = "Allow SSH from source"
  count                       = (((var.create_jump_public_ip && var.create_jump_vm && (length(local.vm_public_access_cidrs) > 0)) || (var.create_nfs_public_ip && var.storage_type == "standard" && (length(local.vm_public_access_cidrs) > 0))) != false) ? 1 : 0
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = local.vm_public_access_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = module.resource_group.name
  network_security_group_name = module.nsg.name
  depends_on                  = [module.nsg]
}

resource "azurerm_container_registry" "acr" {
  count                    = var.create_container_registry ? 1 : 0
  name                     = join("", regexall("[a-zA-Z0-9]+", "${var.prefix}acr")) # alpha numeric characters only are allowed
  resource_group_name      = module.resource_group.name
  location                 = var.location
  sku                      = local.container_registry_sku
  admin_enabled            = var.container_registry_admin_enabled
  
  #
  # Moving from deprecated argument, georeplication_locations, but keeping container_registry_geo_replica_locs
  # for backwards compatability.
  #
  georeplications = (local.container_registry_sku == "Premium" && var.container_registry_geo_replica_locs != null) ? [
    for location_item in var.container_registry_geo_replica_locs:
      {
        location = location_item
        tags     = var.tags
      }
  ] : local.container_registry_sku == "Premium" ? [] : null

  tags                     = module.resource_group.tags
  depends_on               = [module.resource_group]
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
  resource_group_name         = module.resource_group.name
  network_security_group_name = module.nsg.name
  depends_on                  = [module.nsg]
}

module "aks" {
  source = "./modules/azure_aks"

  aks_cluster_name                         = "${var.prefix}-aks"
  aks_cluster_rg                           = module.resource_group.name
  aks_cluster_rg_id                        = module.resource_group.id
  aks_cluster_dns_prefix                   = "${var.prefix}-aks"
  aks_cluster_location                     = var.location
  aks_cluster_node_auto_scaling            = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? false : true
  aks_cluster_node_count                   = var.default_nodepool_min_nodes
  aks_cluster_min_nodes                    = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? null : var.default_nodepool_min_nodes
  aks_cluster_max_nodes                    = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? null : var.default_nodepool_max_nodes
  aks_cluster_max_pods                     = var.default_nodepool_max_pods
  aks_cluster_os_disk_size                 = var.default_nodepool_os_disk_size
  aks_cluster_node_vm_size                 = var.default_nodepool_vm_type
  aks_cluster_node_admin                   = var.node_vm_admin
  aks_cluster_ssh_public_key               = file(var.ssh_public_key)
  aks_vnet_subnet_id                       = module.vnet.subnets["aks"].id
  kubernetes_version                       = var.kubernetes_version
  aks_cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs
  aks_availability_zones                   = var.default_nodepool_availability_zones
  aks_oms_enabled                          = var.create_aks_azure_monitor
  aks_log_analytics_workspace_id           = var.create_aks_azure_monitor ? azurerm_log_analytics_workspace.viya4[0].id : null
  aks_network_plugin                       = var.aks_network_plugin
  aks_network_policy                       = var.aks_network_policy
  aks_dns_service_ip                       = var.aks_dns_service_ip
  aks_docker_bridge_cidr                   = var.aks_docker_bridge_cidr
  aks_outbound_type                        = var.aks_outbound_type
  aks_pod_cidr                             = var.aks_pod_cidr
  aks_service_cidr                         = var.aks_service_cidr
  aks_cluster_tags                         = module.resource_group.tags
  depends_on                               = [module.vnet]
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
  depends_on               = [ module.aks ]
}

module "node_pools" {
  source = "./modules/aks_node_pool"

  for_each = var.node_pools

  node_pool_name = each.key
  aks_cluster_id = module.aks.cluster_id
  vnet_subnet_id = module.vnet.subnets["aks"].id
  machine_type   = each.value.machine_type
  os_disk_size   = each.value.os_disk_size
  # TODO: enable with azurerm v2.37.0
  #  os_disk_type                 = each.value.os_disk_type
  enable_auto_scaling          = each.value.min_nodes == each.value.max_nodes ? false : true
  node_count                   = each.value.min_nodes
  min_nodes                    = each.value.min_nodes == each.value.max_nodes ? null : each.value.min_nodes
  max_nodes                    = each.value.min_nodes == each.value.max_nodes ? null : each.value.max_nodes
  max_pods                     = each.value.max_pods == null ? 110 : each.value.max_pods
  node_taints                  = each.value.node_taints
  node_labels                  = each.value.node_labels
  availability_zones           = (var.node_pools_availability_zone == "" || var.node_pools_proximity_placement == true) ? [] : [var.node_pools_availability_zone]
  proximity_placement_group_id = element(coalescelist(azurerm_proximity_placement_group.proximity.*.id, [""]), 0)
  orchestrator_version         = var.kubernetes_version
  tags                         = module.resource_group.tags
}

# Module Registry - https://registry.terraform.io/modules/Azure/postgresql/azurerm/2.1.0
module "postgresql" {
  source  = "Azure/postgresql/azurerm"
  version = "2.1.0"

  count                        = var.create_postgres ? 1 : 0
  resource_group_name          = module.resource_group.name
  location                     = var.location
  server_name                  = lower("${var.prefix}-pgsql")
  sku_name                     = var.postgres_sku_name
  storage_mb                   = var.postgres_storage_mb
  backup_retention_days        = var.postgres_backup_retention_days
  geo_redundant_backup_enabled = var.postgres_geo_redundant_backup_enabled
  administrator_login          = var.postgres_administrator_login
  administrator_password       = var.postgres_administrator_password
  server_version               = var.postgres_server_version
  ssl_enforcement_enabled      = var.postgres_ssl_enforcement_enabled
  db_names                     = var.postgres_db_names
  db_charset                   = var.postgres_db_charset
  db_collation                 = var.postgres_db_collation
  firewall_rule_prefix         = "${var.prefix}-postgres-firewall-"
  firewall_rules               = local.postgres_firewall_rules
  vnet_rule_name_prefix        = "${var.prefix}-postgresql-vnet-rule-"
  postgresql_configurations    = var.postgres_configurations
  tags                         = module.resource_group.tags

  ## TODO : requires specific permissions
  vnet_rules = [{ name = "aks", subnet_id = module.vnet.subnets["aks"].id }, { name = "misc", subnet_id = module.vnet.subnets["misc"].id }]
  depends_on = [module.resource_group]
}

module "netapp" {
  source        = "./modules/azurerm_netapp"
  count                = var.storage_type == "ha" ? 1 : 0

  prefix                = var.prefix
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  vnet_name             = module.vnet.name
  subnet_id             = module.vnet.subnets["netapp"].id
  service_level         = var.netapp_service_level
  size_in_tb            = var.netapp_size_in_tb
  protocols             = var.netapp_protocols
  volume_path           = "${var.prefix}-${var.netapp_volume_path}"
  tags                  = module.resource_group.tags
  allowed_clients       = concat(module.vnet.subnets["aks"].address_prefixes, module.vnet.subnets["misc"].address_prefixes)
  depends_on            = [module.vnet]
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

  depends_on = [ module.aks ]
}
