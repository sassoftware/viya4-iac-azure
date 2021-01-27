terraform {
  required_version = "~> 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.43.0"
    }
    azureread = {
      source  = "hashicorp/azuread"
      version = "1.2.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.0.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.11"
    }
  }
}

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

  load_config_file = false
}


data "azurerm_subscription" "current" {}

locals {
  # Network ip ranges
  vnet_cidr_block          = "192.168.0.0/16"
  aks_subnet_cidr_block    = "192.168.16.0/20"
  misc_subnet_cidr_block   = "192.168.2.0/24"
  gw_subnet_cidr_block     = "192.168.3.0/24"
  netapp_subnet_cidr_block = "192.168.0.0/24"
  # Subnets
  aks_subnet_name  = "${var.prefix}-aks-subnet"
  misc_subnet_name = "${var.prefix}-misc-subnet"
  # Jump VM
  create_jump_vm_default = var.storage_type != "dev" ? true : false
  create_jump_vm         = var.create_jump_vm != null ? var.create_jump_vm : local.create_jump_vm_default
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

}

resource "azurerm_resource_group" "azure_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_proximity_placement_group" "proximity" {
  count = var.node_pools_proximity_placement ? 1 : 0

  name                = "${var.prefix}-ProximityPlacementGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure_rg.name

  tags = var.tags
}
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure_rg.name

  tags = var.tags
}

# Module registry: https://registry.terraform.io/modules/Azure/vnet/azurerm/2.3.0
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "2.3.0"

  vnet_name           = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.azure_rg.name
  address_space       = [local.vnet_cidr_block]
  subnet_prefixes     = [local.aks_subnet_cidr_block, local.misc_subnet_cidr_block]
  subnet_names        = [local.aks_subnet_name, local.misc_subnet_name]

  subnet_service_endpoints = {
    coalesce(local.aks_subnet_name)  = ["Microsoft.Sql"],
    coalesce(local.misc_subnet_name) = ["Microsoft.Sql"]
  }
  tags = var.tags

  depends_on = [azurerm_resource_group.azure_rg]
}

data "azurerm_subnet" "aks-subnet" {
  name                 = local.aks_subnet_name
  virtual_network_name = module.vnet.vnet_name
  resource_group_name  = azurerm_resource_group.azure_rg.name

  depends_on = [module.vnet]
}

data "azurerm_subnet" "misc-subnet" {
  name                 = local.misc_subnet_name
  virtual_network_name = module.vnet.vnet_name
  resource_group_name  = azurerm_resource_group.azure_rg.name

  depends_on = [module.vnet]
}

data "template_file" "jump-cloudconfig" {
  template = file("${path.module}/cloud-init/jump/cloud-config")
  vars = {
    rwx_filestore_endpoint = var.storage_type == "dev" ? "" : coalesce(module.netapp.netapp_endpoint, module.nfs.private_ip_address)
    rwx_filestore_path     = var.storage_type == "dev" ? "" : coalesce(module.netapp.netapp_path, "/export")
  }

  depends_on = [module.netapp, module.nfs]
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
  name              = "${var.prefix}-jump"
  azure_rg_name     = azurerm_resource_group.azure_rg.name
  azure_rg_location = var.location
  vnet_subnet_id    = data.azurerm_subnet.misc-subnet.id
  azure_nsg_id      = azurerm_network_security_group.nsg.id
  tags              = var.tags
  create_vm         = local.create_jump_vm
  vm_admin          = var.jump_vm_admin
  ssh_public_key    = file(var.ssh_public_key)
  cloud_init        = var.storage_type == "dev" ? null : data.template_cloudinit_config.jump.rendered
  create_public_ip  = var.create_jump_public_ip
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "${var.prefix}-ssh"
  description                 = "Allow SSH from source"
  count                       = (var.create_jump_public_ip && local.create_jump_vm && length(local.vm_public_access_cidrs) != 0) ? 1 : 0
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = local.vm_public_access_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.azure_rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

data "template_file" "nfs-cloudconfig" {
  template = file("${path.module}/cloud-init/nfs/cloud-config")
  vars = {
    base_cidr_block = local.vnet_cidr_block
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
  source    = "./modules/azurerm_vm"
  create_vm = var.storage_type == "standard" ? true : false

  name                         = "${var.prefix}-nfs"
  azure_rg_name                = azurerm_resource_group.azure_rg.name
  azure_rg_location            = var.location
  proximity_placement_group_id = element(coalescelist(azurerm_proximity_placement_group.proximity.*.id, [""]), 0)
  vnet_subnet_id               = data.azurerm_subnet.misc-subnet.id
  azure_nsg_id                 = azurerm_network_security_group.nsg.id
  tags                         = var.tags
  data_disk_count              = 4
  data_disk_size               = var.nfs_raid_disk_size
  vm_admin                     = var.nfs_vm_admin
  ssh_public_key               = file(var.ssh_public_key)
  cloud_init                   = data.template_cloudinit_config.nfs.rendered
  create_public_ip             = var.create_nfs_public_ip
}

resource "azurerm_container_registry" "acr" {
  count = var.create_container_registry ? 1 : 0

  name                     = join("", regexall("[a-zA-Z0-9]+", "${var.prefix}acr")) # alpha numeric characters only are allowed
  resource_group_name      = azurerm_resource_group.azure_rg.name
  location                 = var.location
  sku                      = var.container_registry_sku
  admin_enabled            = var.container_registry_admin_enabled
  georeplication_locations = var.container_registry_geo_replica_locs
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
  resource_group_name         = azurerm_resource_group.azure_rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

module "aks" {
  source = "./modules/azure_aks"

  aks_cluster_name = "${var.prefix}-aks"
  aks_cluster_rg   = azurerm_resource_group.azure_rg.name
  #aks_cluster_dns_prefix - must contain between 2 and 45 characters. The name can contain only letters, numbers, and hyphens. The name must start with a letter and must end with an alphanumeric character
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
  aks_vnet_subnet_id                       = data.azurerm_subnet.aks-subnet.id
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
  aks_cluster_tags                         = var.tags
}

data "azurerm_public_ip" "aks_public_ip" {
  name                = split("/", module.aks.cluster_slb_ip_id)[8]
  resource_group_name = "MC_${azurerm_resource_group.azure_rg.name}_${module.aks.name}_${azurerm_resource_group.azure_rg.location}"

  depends_on = [module.aks, module.node_pools]
}


module "node_pools" {
  source = "./modules/aks_node_pool"

  for_each = var.node_pools

  node_pool_name = each.key
  aks_cluster_id = module.aks.cluster_id
  vnet_subnet_id = data.azurerm_subnet.aks-subnet.id
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
  tags                         = var.tags
}

# Module Registry - https://registry.terraform.io/modules/Azure/postgresql/azurerm/2.1.0
module "postgresql" {
  source  = "Azure/postgresql/azurerm"
  version = "2.1.0"

  count = var.create_postgres ? 1 : 0

  resource_group_name          = azurerm_resource_group.azure_rg.name
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
  tags                         = var.tags
  vnet_rules = [
    { name = local.aks_subnet_name, subnet_id = data.azurerm_subnet.aks-subnet.id },
    { name = local.misc_subnet_name, subnet_id = data.azurerm_subnet.misc-subnet.id }
  ]

  depends_on = [azurerm_resource_group.azure_rg]
}

module "netapp" {
  source        = "./modules/azurerm_netapp"
  create_netapp = var.storage_type == "ha" ? true : false

  prefix                = var.prefix
  resource_group_name   = azurerm_resource_group.azure_rg.name
  location              = azurerm_resource_group.azure_rg.location
  vnet_name             = module.vnet.vnet_name
  subnet_address_prefix = [local.netapp_subnet_cidr_block]
  service_level         = var.netapp_service_level
  size_in_tb            = var.netapp_size_in_tb
  protocols             = var.netapp_protocols
  volume_path           = "${var.prefix}-${var.netapp_volume_path}"
  tags                  = var.tags
}

resource "local_file" "kubeconfig" {
  content  = module.aks.kube_config
  filename = local.kubeconfig_path
}

data "external" "git_hash" {
  program = ["git", "log", "-1", "--format=format:{ \"git-hash\": \"%H\" }"]
}

data "external" "iac_tooling_version" {
  program = ["files/iac_tooling_version.sh"]
}

resource "kubernetes_config_map" "sas_iac_buildinfo" {
  metadata {
    name      = "sas-iac-buildinfo"
    namespace = "kube-system"
  }

  data = {
    git-hash    = lookup(data.external.git_hash.result, "git-hash")
    timestamp   = chomp(timestamp())
    iac-tooling = var.iac_tooling
    terraform   = <<EOT
      version: ${lookup(data.external.iac_tooling_version.result, "terraform_version")}
      revision: ${lookup(data.external.iac_tooling_version.result, "terraform_revision")}
      provider-selections: ${lookup(data.external.iac_tooling_version.result, "provider_selections")}
      outdated: ${lookup(data.external.iac_tooling_version.result, "terraform_outdated")}
EOT
  }
}

