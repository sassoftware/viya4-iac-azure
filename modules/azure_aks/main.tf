# Reference: 
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.aks_cluster_location
  resource_group_name = var.aks_cluster_rg
  dns_prefix          = var.aks_cluster_dns_prefix
  # https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions
  # az aks get-versions --location eastus -o table
  kubernetes_version              = var.kubernetes_version
  api_server_authorized_ip_ranges = var.aks_cluster_endpoint_public_access_cidrs

  network_profile {
    network_plugin = var.aks_network_plugin
    network_policy = var.aks_network_plugin == "azure" ? var.aks_network_policy : null
    # Docs on AKS Advanced Networking config
    # https://docs.microsoft.com/en-gb/azure/architecture/aws-professional/networking
    # https://docs.microsoft.com/en-gb/azure/virtual-network/virtual-network-vnet-plan-design-arm
    # https://github.com/terraform-providers/terraform-provider-azurerm/issues/4322
    # https://docs.microsoft.com/en-us/azure/aks/internal-lb
    # https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard
    # https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype

    service_cidr       = var.aks_network_plugin == "kubenet" ? "10.0.0.0/16" : var.aks_service_cidr
    dns_service_ip     = var.aks_network_plugin == "kubenet" ? "10.0.0.10" : var.aks_dns_service_ip
    pod_cidr           = var.aks_network_plugin == "kubenet" ? "10.244.0.0/16" : null
    docker_bridge_cidr = var.aks_network_plugin == "kubenet" ? "172.17.0.1/16" : var.aks_docker_bridge_cidr

    # load_balancer_sku = "Standard"
  }

  role_based_access_control {
    enabled = true
  }

  linux_profile {
    admin_username = var.aks_cluster_node_admin
    ssh_key {
      key_data = var.aks_cluster_ssh_public_key
    }
  }

  default_node_pool {
    name                  = "system"
    vm_size               = var.aks_cluster_node_vm_size
    availability_zones    = var.aks_availability_zones
    enable_auto_scaling   = var.aks_cluster_node_auto_scaling
    enable_node_public_ip = false
    node_labels           = {}
    node_taints           = []
    max_pods              = var.aks_cluster_max_pods
    os_disk_size_gb       = var.aks_cluster_os_disk_size
    max_count             = var.aks_cluster_max_nodes
    min_count             = var.aks_cluster_min_nodes
    node_count            = var.aks_cluster_node_count
    vnet_subnet_id        = var.aks_vnet_subnet_id
    tags                  = var.aks_cluster_tags
  }

  service_principal {
    client_id     = var.aks_client_id
    client_secret = var.aks_client_secret
  }

  addon_profile {
    http_application_routing {
      enabled = false
    }
    kube_dashboard {
      enabled = false
    }
    oms_agent {
      enabled                    = var.aks_oms_enabled
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
    ignore_changes = [default_node_pool.0.node_count]
  }


  tags = var.aks_cluster_tags
}
