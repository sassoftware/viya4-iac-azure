
# For more information on configuring TFlint; see https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md

# For more information on plugins see https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/plugins.md

# For more information on TFlint Ruleset for Terraform; see https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.3.0/docs/rules/README.md

# For more information on TFlint Ruleset for Azure, see https://github.com/terraform-linters/tflint-ruleset-azurerm/blob/master/docs/README.md

config {
  # Enables module inspection.
  module = true
  variables = ["ssh_public_key=null"]
}

plugin "azurerm" {
    enabled = true
    version = "0.23.0"
    source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "terraform" {
  enabled = true
  preset = "recommended"
}

rule "azurerm_kubernetes_cluster_default_node_pool_invalid_vm_size" {
  enabled = false
}

# We specify the versions and providers in the top level versions.tf.
# This stops it from throwing a warning when scanning our modules
# in viya4-iac-azure/modules/
rule "terraform_required_version" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = false
}
