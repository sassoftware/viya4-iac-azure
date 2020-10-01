terraform {
  required_version = ">= 0.13"
  # Experimental features 
  # https://www.terraform.io/docs/configuration/terraform.html#experimental-language-features
  # experiments = [variable_validation]
}

provider "azurerm" {
  version = "~>2.28.0"

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  features {}
}

provider "cloudinit" {
  version = "1.0.0"
}

data "azurerm_subscription" "current" {}

data "azuread_service_principal" "sp_client" {
  application_id = var.client_id
}

locals {
  # Network ip ranges
  vnet_cidr_block        = "192.168.0.0/16"
  aks_subnet_cidr_block  = "192.168.1.0/24"
  misc_subnet_cidr_block = "192.168.2.0/24"
  gw_subnet_cidr_block   = "192.168.3.0/24"
  create_jump_vm_default = var.storage_type != "dev" ? true : false
  create_jump_vm         = var.create_jump_vm != null ? var.create_jump_vm : local.create_jump_vm_default

}

module "azure_rg" {
  source = "./modules/azurerm_resource_group"

  azure_rg_name     = "${var.prefix}-rg"
  azure_rg_location = var.location
  tags              = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = module.azure_rg.name

  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = module.azure_rg.name
  address_space       = [local.vnet_cidr_block]
  tags                = var.tags
}

module "gw-subnet" {
  source            = "./modules/azure_subnet"
  name              = "${var.prefix}-gw"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  nsg               = azurerm_network_security_group.nsg
  address_prefixes  = [local.gw_subnet_cidr_block]
  vnet_name         = azurerm_virtual_network.vnet.name
  service_endpoints = var.create_postgres ? ["Microsoft.Sql"] : []
  tags              = var.tags
}

module "aks-subnet" {
  source            = "./modules/azure_subnet"
  name              = "${var.prefix}-aks"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  address_prefixes  = [local.aks_subnet_cidr_block]
  vnet_name         = azurerm_virtual_network.vnet.name
  service_endpoints = var.create_postgres ? ["Microsoft.Sql"] : []
  tags              = var.tags
}

module "misc-subnet" {
  source            = "./modules/azure_subnet"
  name              = "${var.prefix}-misc"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  nsg               = azurerm_network_security_group.nsg
  address_prefixes  = [local.misc_subnet_cidr_block]
  vnet_name         = azurerm_virtual_network.vnet.name
  service_endpoints = var.create_postgres ? ["Microsoft.Sql"] : []
  tags              = var.tags
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
    content      = "${data.template_file.jump-cloudconfig.rendered}"
  }
}

module "jump" {
  source            = "./modules/azurerm_vm"
  name              = "${var.prefix}-jump"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  vnet_subnet_id    = module.misc-subnet.subnet_id
  azure_nsg_id      = azurerm_network_security_group.nsg.id
  tags              = var.tags
  create_vm         = local.create_jump_vm
  vm_admin          = var.jump_vm_admin
  ssh_public_key    = var.ssh_public_key
  # ssh_private_key   = var.ssh_private_key
  cloud_init       = var.storage_type == "dev" ? null : data.template_cloudinit_config.jump.rendered
  create_public_ip = var.create_jump_public_ip
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "${var.prefix}-ssh"
  description                 = "Allow SSH from source"
  count                       = (var.create_jump_public_ip && local.create_jump_vm) ? 1 : 0
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.cluster_endpoint_public_access_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = module.azure_rg.name
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
    content      = "${data.template_file.nfs-cloudconfig.rendered}"
  }
}

module "nfs" {
  source    = "./modules/azurerm_vm"
  create_vm = var.storage_type == "standard" ? true : false

  name              = "${var.prefix}-nfs"
  azure_rg_name     = module.azure_rg.name
  azure_rg_location = var.location
  vnet_subnet_id    = module.misc-subnet.subnet_id
  azure_nsg_id      = azurerm_network_security_group.nsg.id
  tags              = var.tags
  data_disk_count   = 4
  data_disk_size    = var.nfs_raid_disk_size
  vm_admin          = var.nfs_vm_admin
  ssh_public_key    = var.ssh_public_key
  # ssh_private_key   = var.ssh_private_key
  cloud_init       = data.template_cloudinit_config.nfs.rendered
  create_public_ip = var.create_nfs_public_ip
}

module "acr" {
  source                              = "./modules/azurerm_container_registry"
  create_container_registry           = var.create_container_registry
  container_registry_name             = join("", regexall("[a-zA-Z0-9]+", "${var.prefix}acr")) # alpha numeric characters only are allowed
  container_registry_rg               = module.azure_rg.name
  container_registry_location         = var.location
  container_registry_sku              = var.container_registry_sku
  container_registry_admin_enabled    = var.container_registry_admin_enabled
  container_registry_geo_replica_locs = var.container_registry_geo_replica_locs
  container_registry_sp_role          = data.azuread_service_principal.sp_client.id
}

resource "azurerm_network_security_rule" "acr" {
  name                        = "SAS-ACR"
  description                 = "Allow ACR from source"
  count                       = var.create_container_registry ? 1 : 0
  priority                    = 180
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5000"
  source_address_prefixes     = var.cluster_endpoint_public_access_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = module.azure_rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

module "aks" {
  source = "./modules/azure_aks"

  aks_cluster_name = "${var.prefix}-aks"
  aks_cluster_rg   = module.azure_rg.name
  #aks_cluster_dns_prefix - must contain between 2 and 45 characters. The name can contain only letters, numbers, and hyphens. The name must start with a letter and must end with an alphanumeric character
  aks_cluster_dns_prefix                   = "${var.prefix}-aks"
  aks_cluster_location                     = var.location
  aks_cluster_node_auto_scaling            = var.default_nodepool_auto_scaling
  aks_cluster_max_nodes                    = var.default_nodepool_max_nodes
  aks_cluster_min_nodes                    = var.default_nodepool_min_nodes
  aks_cluster_node_count                   = var.default_nodepool_node_count
  aks_cluster_max_pods                     = var.default_nodepool_max_pods
  aks_cluster_os_disk_size                 = var.default_nodepool_os_disk_size
  aks_cluster_node_vm_size                 = var.default_nodepool_vm_type
  aks_cluster_node_admin                   = var.node_vm_admin
  aks_cluster_ssh_public_key               = var.ssh_public_key
  aks_vnet_subnet_id                       = module.aks-subnet.subnet_id
  aks_client_id                            = var.client_id
  aks_client_secret                        = var.client_secret
  kubernetes_version                       = var.kubernetes_version
  aks_cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  aks_availability_zones                   = var.default_nodepool_availability_zones
  aks_cluster_tags                         = var.tags
}

data "azurerm_public_ip" "aks_public_ip" {
  # "/subscriptions/<subscription-id-00000-0000>/resourceGroups/MC_<rg-name>_<aks-name>_<rg-location>/providers/Microsoft.Network/publicIPAddresses/16172d45-fd0a-413c-b8e5-957667bbfaab"
  name                = split("/", module.aks.cluster_slb_ip_id)[8]
  resource_group_name = "MC_${module.azure_rg.name}_${module.aks.name}_${module.azure_rg.location}"

  depends_on = [module.aks, module.cas_node_pool, module.compute_node_pool, module.connect_node_pool, module.stateless_node_pool, module.stateful_node_pool]
}


module "cas_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_cas_nodepool
  node_pool_name      = "cas" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.cas_nodepool_vm_type
  os_disk_size        = var.cas_nodepool_os_disk_size
  enable_auto_scaling = var.cas_nodepool_auto_scaling
  node_count          = var.cas_nodepool_node_count
  max_nodes           = var.cas_nodepool_max_nodes
  min_nodes           = var.cas_nodepool_min_nodes
  node_taints         = var.cas_nodepool_taints
  node_labels         = var.cas_nodepool_labels
  availability_zones  = var.cas_nodepool_availability_zones
  tags                = var.tags
}

module "compute_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_compute_nodepool
  node_pool_name      = "compute" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.compute_nodepool_vm_type
  os_disk_size        = var.compute_nodepool_os_disk_size
  enable_auto_scaling = var.compute_nodepool_auto_scaling
  node_count          = var.compute_nodepool_node_count
  max_nodes           = var.compute_nodepool_max_nodes
  min_nodes           = var.compute_nodepool_min_nodes
  node_taints         = var.compute_nodepool_taints
  node_labels         = var.compute_nodepool_labels
  availability_zones  = var.compute_nodepool_availability_zones
  tags                = var.tags
}

module "connect_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_connect_nodepool
  node_pool_name      = "connect" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.connect_nodepool_vm_type
  os_disk_size        = var.connect_nodepool_os_disk_size
  enable_auto_scaling = var.connect_nodepool_auto_scaling
  node_count          = var.connect_nodepool_node_count
  max_nodes           = var.connect_nodepool_max_nodes
  min_nodes           = var.connect_nodepool_min_nodes
  node_taints         = var.connect_nodepool_taints
  node_labels         = var.connect_nodepool_labels
  availability_zones  = var.connect_nodepool_availability_zones
  tags                = var.tags
}

module "stateless_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_stateless_nodepool
  node_pool_name      = "stateless" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.stateless_nodepool_vm_type
  os_disk_size        = var.stateless_nodepool_os_disk_size
  enable_auto_scaling = var.stateless_nodepool_auto_scaling
  node_count          = var.stateless_nodepool_node_count
  max_nodes           = var.stateless_nodepool_max_nodes
  min_nodes           = var.stateless_nodepool_min_nodes
  node_taints         = var.stateless_nodepool_taints
  node_labels         = var.stateless_nodepool_labels
  availability_zones  = var.stateless_nodepool_availability_zones
  tags                = var.tags
}

module "stateful_node_pool" {
  source              = "./modules/aks_node_pool"
  create_node_pool    = var.create_stateful_nodepool
  node_pool_name      = "stateful" # <- characters a-z0-9 only with max length of 12
  aks_cluster_id      = module.aks.cluster_id
  vnet_subnet_id      = module.aks-subnet.subnet_id
  machine_type        = var.stateful_nodepool_vm_type
  os_disk_size        = var.stateful_nodepool_os_disk_size
  enable_auto_scaling = var.stateful_nodepool_auto_scaling
  node_count          = var.stateful_nodepool_node_count
  max_nodes           = var.stateful_nodepool_max_nodes
  min_nodes           = var.stateful_nodepool_min_nodes
  node_taints         = var.stateful_nodepool_taints
  node_labels         = var.stateful_nodepool_labels
  availability_zones  = var.stateful_nodepool_availability_zones
  tags                = var.tags
}

module "postgresql" {
  source          = "./modules/postgresql"
  create_postgres = var.create_postgres

  resource_group_name             = module.azure_rg.name
  postgres_administrator_login    = var.postgres_administrator_login
  postgres_administrator_password = var.postgres_administrator_password
  location                        = var.location
  # "server_name" match regex "^[0-9a-z][-0-9a-z]{1,61}[0-9a-z]$"
  # "server_name" can contain only lowercase letters, numbers, and '-', but can't start or end with '-'. And must be at least 3 characters and at most 63 characters
  server_name                           = lower("${var.prefix}-pgsql")
  postgres_sku_name                     = var.postgres_sku_name
  postgres_storage_mb                   = var.postgres_storage_mb
  postgres_backup_retention_days        = var.postgres_backup_retention_days
  postgres_geo_redundant_backup_enabled = var.postgres_geo_redundant_backup_enabled
  tags                                  = var.tags
  postgres_server_version               = var.postgres_server_version
  postgres_ssl_enforcement_enabled      = var.postgres_ssl_enforcement_enabled
  postgres_db_names                     = var.postgres_db_names
  postgres_db_charset                   = var.postgres_db_charset
  postgres_db_collation                 = var.postgres_db_collation
  postgres_firewall_rule_prefix         = "${var.prefix}-postgres-firewall-"
  postgres_firewall_rules               = var.postgres_firewall_rules
  postgres_vnet_rule_prefix             = "${var.prefix}-postgresql-vnet-rule-"
  postgres_vnet_rules                   = [{ name = module.misc-subnet.subnet_name, subnet_id = module.misc-subnet.subnet_id }, { name = module.aks-subnet.subnet_name, subnet_id = module.aks-subnet.subnet_id }]
}

module "netapp" {
  source        = "./modules/azurerm_netapp"
  create_netapp = var.storage_type == "ha" ? true : false

  prefix                = var.prefix
  resource_group_name   = module.azure_rg.name
  location              = module.azure_rg.location
  vnet_name             = azurerm_virtual_network.vnet.name
  subnet_address_prefix = ["192.168.0.0/24"]
  service_level         = var.netapp_service_level
  size_in_tb            = var.netapp_size_in_tb
  protocols             = var.netapp_protocols
  volume_path           = "${var.prefix}-${var.netapp_volume_path}"
}

resource "local_file" "kubeconfig" {
  content  = module.aks.kube_config
  filename = "${var.prefix}-aks-kubeconfig.conf"
}
