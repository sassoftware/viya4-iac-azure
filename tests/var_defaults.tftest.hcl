
variables {
  location = "eastus2"
    prefix = "foobar"
}

run "cluster_sku_tier_should_default_to_Free" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.aks_cluster_sku_tier == "Free"
    error_message = "A default value of \"${var.aks_cluster_sku_tier}\" for aks_cluster_sku_tier was not expected."
  }
}

run "cluster_support_tier_should_default_to_KubernetesOfficial" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.cluster_support_tier == "KubernetesOfficial"
    error_message = "A default value of \"${var.cluster_support_tier}\" for aks_cluster_support_tier was not expected."
  }
}

run "aks_network_plugin_should_default_to_kubenet" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.aks_network_plugin == "kubenet"
    error_message = "A default value of \"${var.aks_network_plugin}\" for aks_network_plugin was not expected."
  }
}

run "cluster_egress_type_should_default_to_What" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.cluster_egress_type != null ? var.cluster_egress_type == "loadBalancer" : false
    error_message = "A default value of \"${var.cluster_egress_type != null ? var.cluster_egress_type : "null"}\" for cluster_egress_type was not expected."
  }

#  "${var.my_var != null ? var.my_var : "default value"}"

}

run "storage_type_should_default_to_standard" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.storage_type == "standard"
    error_message = "A default value of \"${var.storage_type}\" for storage_type was not expected."
  }
}

run "netapp_size_in_tb_should_default_to_4tb" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.netapp_size_in_tb != null ? var.netapp_size_in_tb == 4 : false
    error_message = "A default value of \"${var.netapp_size_in_tb}\" for netapp_size_in_tb was not expected."
  }
}

run "netapp_network_features_should_default_to_Basic" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.netapp_network_features != null ? var.netapp_network_features == "Basic" : false
    error_message = "A default value of \"${var.netapp_network_features != null ? var.netapp_network_features : "null"}\" for netapp_network_features was not expected."
  }
}

run "metrics_category_should_default_to_AllMetrics" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.metric_category.0 == "AllMetrics"
    error_message = "A default value of \"${var.metric_category.0}\" for metrics_category was not expected."
  }
}

run "cluster_api_mode_should_default_to_public" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.cluster_api_mode == "public"
    error_message = "A default value of \"${var.cluster_api_mode}\" for cluster_api_mode was not expected."
  }
}

run "aks_identity_should_default_to_uai" {

  command = plan
  
  variables {
  }

  assert {
    condition     = var.aks_identity == "uai"
    error_message = "A default value of \"${var.aks_identity}\" for aks_identity was not expected."
  }
}
