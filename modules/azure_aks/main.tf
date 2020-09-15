## CO$T$ additonal for cloud monitoring, enable ONLY when needed, uncomment addon_profile in 'azurerm_kubernetes_cluster' below
## Reference: 
## https://azure.microsoft.com/en-us/pricing/details/monitor/
## https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-overview

# resource "random_id" "log_analytics_workspace_name_suffix" {
#     byte_length = 8
# }

# resource "azurerm_log_analytics_workspace" "test" {
#     # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
#     name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
#     location            = var.log_analytics_workspace_location
#     resource_group_name = azurerm_resource_group.k8s.name
#     sku                 = var.log_analytics_workspace_sku
# }

# resource "azurerm_log_analytics_solution" "test" {
#     solution_name         = "ContainerInsights"
#     location              = azurerm_log_analytics_workspace.test.location
#     resource_group_name   = azurerm_resource_group.k8s.name
#     workspace_resource_id = azurerm_log_analytics_workspace.test.id
#     workspace_name        = azurerm_log_analytics_workspace.test.name

#     plan {
#         publisher = "Microsoft"
#         product   = "OMSGallery/ContainerInsights"
#     }
# }

#
# Need to add in ssh_key genertion here as well.
#
resource "tls_private_key" "private_key" {
  count = var.aks_cluster_ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
}

data "tls_public_key" "public_key" {
  count = var.aks_cluster_ssh_public_key == "" ? 1 : 0
  private_key_pem = element(coalescelist(tls_private_key.private_key.*.private_key_pem), 0)
}

locals {
  ssh_public_key = var.aks_cluster_ssh_public_key != "" ? file(var.aks_cluster_ssh_public_key) : element(coalescelist(data.tls_public_key.public_key.*.public_key_openssh, [""]), 0)
}

# Reference: https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.aks_cluster_location
  resource_group_name = var.aks_cluster_rg
  dns_prefix          = var.aks_cluster_dns_prefix
  # https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions
  # az aks get-versions --location eastus -o table
  kubernetes_version  = var.kubernetes_version
  api_server_authorized_ip_ranges = var.aks_cluster_endpoint_public_access_cidrs

  network_profile {
    network_plugin    = var.aks_network_plugin

  # TODOs: research network config
  # https://docs.microsoft.com/en-gb/azure/architecture/aws-professional/networking
  # https://docs.microsoft.com/en-gb/azure/virtual-network/virtual-network-vnet-plan-design-arm

  # TF docs says these are required only when network_plugin is 'azure' 
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
    pod_cidr          = "10.244.0.0/16"
    docker_bridge_cidr= "172.17.0.1/16"

    load_balancer_sku = "Standard"
    # https://github.com/terraform-providers/terraform-provider-azurerm/issues/4322
    # https://docs.microsoft.com/en-us/azure/aks/internal-lb
    # https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard
    # https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype
  }

  role_based_access_control {
      enabled = true
  }

  linux_profile {
      admin_username = var.aks_cluster_node_admin
      ssh_key {
          key_data = local.ssh_public_key
      }
  }

  default_node_pool {
      name            = "system"
      node_count      = var.aks_cluster_node_count
      vm_size         = var.aks_cluster_node_vm_size
      enable_auto_scaling = var.aks_cluster_node_auto_scaling
      vnet_subnet_id      = var.aks_vnet_subnet_id
      availability_zones    = var.aks_availability_zones
  }

  service_principal {
      client_id     = var.aks_client_id
      client_secret = var.aks_client_secret
  }

  addon_profile {
    http_application_routing {
      enabled = false
    }
    # # Uncomment when 'azurerm_log_analytics_workspace' resource is enabled 
    # oms_agent {
    #   enabled                    = true
    #   log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id
    # }
  }

  # change these default timeouts if needed
  timeouts {
    create  = "90m"
    update  = "90m"
    read    = "5m"
    delete  = "90m"
  }

  tags = var.aks_cluster_tags
}