# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Reference: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                               = var.aks_cluster_name
  location                           = var.aks_cluster_location
  resource_group_name                = var.aks_cluster_rg
  dns_prefix                         = var.aks_private_cluster == false || var.aks_cluster_private_dns_zone_id == "" ? var.aks_cluster_dns_prefix : null
  dns_prefix_private_cluster         = var.aks_private_cluster && var.aks_cluster_private_dns_zone_id != "" ? var.aks_cluster_dns_prefix : null

  sku_tier                           = var.aks_cluster_sku_tier
  role_based_access_control_enabled  = true
  http_application_routing_enabled   = false
  
  # https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions
  # az aks get-versions --location eastus -o table
  kubernetes_version                 = var.kubernetes_version
  api_server_authorized_ip_ranges    = var.aks_cluster_endpoint_public_access_cidrs
  private_cluster_enabled            = var.aks_private_cluster
  private_dns_zone_id                = var.aks_private_cluster && var.aks_cluster_private_dns_zone_id != "" ? var.aks_cluster_private_dns_zone_id : (var.aks_private_cluster ? "System" : null)

  network_profile {
    network_plugin = var.aks_network_plugin
    network_policy = var.aks_network_plugin == "kubenet" && var.aks_network_policy == "azure" ? null : var.aks_network_policy

    # Docs on AKS Advanced Networking config
    # https://docs.microsoft.com/en-us/azure/architecture/aws-professional/networking
    # https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-vnet-plan-design-arm
    # https://github.com/terraform-providers/terraform-provider-azurerm/issues/4322
    # https://docs.microsoft.com/en-us/azure/aks/internal-lb
    # https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard
    # https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype

    service_cidr       = var.aks_service_cidr
    dns_service_ip     = var.aks_dns_service_ip
    pod_cidr           = var.aks_network_plugin == "kubenet" ? var.aks_pod_cidr : null
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    outbound_type      = var.cluster_egress_type
    load_balancer_sku  = "standard"
  }

  dynamic "linux_profile" {
    for_each = var.aks_cluster_ssh_public_key == "" ? [] : [1]
    content {
      admin_username = var.aks_cluster_node_admin
      ssh_key {
         key_data = var.aks_cluster_ssh_public_key
      }
    }
  }

  default_node_pool {
    name                  = "system"
    vm_size               = var.aks_cluster_node_vm_size
    zones                 = var.aks_availability_zones
    enable_auto_scaling   = var.aks_cluster_node_auto_scaling
    enable_node_public_ip = false
    node_labels           = {}
    node_taints           = []
    fips_enabled          = var.fips_enabled
    max_pods              = var.aks_cluster_max_pods
    os_disk_size_gb       = var.aks_cluster_os_disk_size
    max_count             = var.aks_cluster_max_nodes
    min_count             = var.aks_cluster_min_nodes
    node_count            = var.aks_cluster_node_count
    vnet_subnet_id        = var.aks_vnet_subnet_id
    tags                  = var.aks_cluster_tags
    orchestrator_version  = var.kubernetes_version
  }

  dynamic "service_principal" {
    for_each = var.aks_uai_id == null ? [1] : []
    content {
      client_id     = var.client_id
      client_secret = var.client_secret
    }
  }

  dynamic "identity" {
    for_each = var.aks_uai_id == null ? [] : [1]
    content {
      type = "UserAssigned"
      identity_ids = [var.aks_uai_id]
    }
  }

  dynamic "oms_agent" {
    for_each = var.aks_oms_enabled ? ["oms_agent"] : []
    content {
      log_analytics_workspace_id = var.aks_log_analytics_workspace_id
    }
  }

  # change these default timeouts if needed
  timeouts {
    create = "90m"
    update = "90m"
    read   = "5m"
    delete = "90m"
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  tags = var.aks_cluster_tags

}

 data "azurerm_public_ip" "cluster_public_ip" {
  count               = var.cluster_egress_type == "loadBalancer" ? 1 : 0

  # effective_outbound_ips is a set of strings, that needs to be converted to a list type
  name                = split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0])[8]
  resource_group_name = "MC_${var.aks_cluster_rg}_${var.aks_cluster_name}_${var.aks_cluster_location}"

  depends_on = [azurerm_kubernetes_cluster.aks]
}
