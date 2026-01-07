# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Reference: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                       = var.aks_cluster_name
  location                   = var.aks_cluster_location
  resource_group_name        = var.aks_cluster_rg
  node_resource_group        = var.node_resource_group_name
  dns_prefix                 = var.aks_private_cluster == false || var.aks_cluster_private_dns_zone_id == "" ? var.aks_cluster_dns_prefix : null
  dns_prefix_private_cluster = var.aks_private_cluster && var.aks_cluster_private_dns_zone_id != "" ? var.aks_cluster_dns_prefix : null

  sku_tier                          = var.aks_cluster_sku_tier
  support_plan                      = var.cluster_support_tier
  node_os_upgrade_channel           = var.community_node_os_upgrade_channel
  role_based_access_control_enabled = true
  http_application_routing_enabled  = false
  disk_encryption_set_id            = var.aks_node_disk_encryption_set_id
  azure_policy_enabled              = var.aks_azure_policy_enabled

  # https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions
  # az aks get-versions --location eastus -o table
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.aks_private_cluster
  private_dns_zone_id     = var.aks_private_cluster && var.aks_cluster_private_dns_zone_id != "" ? var.aks_cluster_private_dns_zone_id : (var.aks_private_cluster ? "System" : null)
  run_command_enabled     = var.aks_cluster_run_command_enabled
  ip_family               = var.enable_ipv6 ? "dualstack" : null

  # OIDC issuer must always be enabled if workload identity is enabled
  oidc_issuer_enabled       = var.enable_workload_identity
  workload_identity_enabled = var.enable_workload_identity

  network_profile {
    # Docs on AKS Advanced Networking config
    # https://docs.microsoft.com/en-us/azure/architecture/aws-professional/networking
    # https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-vnet-plan-design-arm
    # https://github.com/terraform-providers/terraform-provider-azurerm/issues/4322
    # https://docs.microsoft.com/en-us/azure/aks/internal-lb
    # https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard
    # https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype

    network_plugin      = var.aks_network_plugin
    network_policy      = var.aks_network_policy
    network_plugin_mode = var.aks_network_plugin_mode
    service_cidr        = var.aks_service_cidr
    dns_service_ip      = var.aks_dns_service_ip
    pod_cidr = (
      var.aks_network_plugin == "kubenet" ||
      (var.aks_network_plugin == "azure" && var.aks_network_plugin_mode == "overlay")
    ) ? var.aks_pod_cidr : null
    # IPv6 pod CIDR configuration for dual-stack Azure CNI
    ipv6_pod_cidr = var.enable_ipv6 ? var.aks_pod_ipv6_cidr : null
    # NOTE: service_ipv6_cidr is not supported by the current Terraform azurerm
    # provider for azurerm_kubernetes_cluster. IPv6 service CIDR configuration
    # requires either a provider update or manual configuration via Azure CLI.
    # Example: az aks update --resource-group <rg> --name <cluster> \
    #   --enable-ipv6 --ipv6-service-ipv6-cidr 2001:db8:1::/108
    outbound_type       = var.cluster_egress_type
    load_balancer_sku   = var.load_balancer_sku
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.aks_cluster_endpoint_public_access_cidrs) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.aks_cluster_endpoint_public_access_cidrs
    }
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

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.rbac_aad_enabled ? [1] : []
    content {
      tenant_id              = var.rbac_aad_tenant_id
      admin_group_object_ids = var.rbac_aad_admin_group_object_ids
      azure_rbac_enabled     = var.rbac_aad_azure_rbac_enabled
    }
  }

  default_node_pool {
    name                    = "system"
    vm_size                 = var.aks_cluster_node_vm_size
    zones                   = var.aks_availability_zones
    auto_scaling_enabled    = var.aks_cluster_node_auto_scaling
    node_public_ip_enabled  = false
    node_labels             = {}
    fips_enabled            = var.fips_enabled
    host_encryption_enabled = var.aks_cluster_enable_host_encryption
    max_pods                = var.aks_cluster_max_pods
    os_disk_size_gb         = var.aks_cluster_os_disk_size
    max_count               = var.aks_cluster_max_nodes
    min_count               = var.aks_cluster_min_nodes
    node_count              = var.aks_cluster_node_count
    vnet_subnet_id          = var.aks_vnet_subnet_id
    tags                    = var.aks_cluster_tags
    orchestrator_version    = var.kubernetes_version
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
      type         = "UserAssigned"
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
    precondition {
      condition     = var.aks_network_policy != "azure" || var.aks_network_plugin == "azure"
      error_message = "When aks_network_policy is set to `azure`, the aks_network_plugin field can only be set to `azure`."
    }
    precondition {
      condition     = var.aks_network_plugin_mode != "overlay" || var.aks_network_plugin == "azure"
      error_message = "When network_plugin_mode is set to `overlay`, the aks_network_plugin field can only be set to `azure`."
    }
  }

  tags = var.aks_cluster_tags

}

data "azurerm_public_ip" "cluster_public_ip" {
  count = var.cluster_egress_type == "loadBalancer" ? 1 : 0

  # effective_outbound_ips is a set of strings, that needs to be converted to a list type
  name                = split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0])[8]
  resource_group_name = var.node_resource_group_name

  depends_on = [azurerm_kubernetes_cluster.aks]
}
