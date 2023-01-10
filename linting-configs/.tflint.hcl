config {
  module = true
}

plugin "azurerm" {
    enabled = true
    version = "0.14.0"
    source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

rule "azurerm_kubernetes_cluster_default_node_pool_invalid_vm_size" {
  enabled = false
}
