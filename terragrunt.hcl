
remote_state {
  backend = "azurerm" 
  config = {
    storage_account_name = "${get_env("storage_account", "ecdeploy")}"
    container_name       = "terraformbackend"
    key                  = "${get_env("TF_VAR_ENV", "empty")}/${get_env("TF_VAR_COMPONENT", "empty")}/${get_env("TF_VAR_VERSION", "vx.x.x")}/terraform.tfstate"
    access_key           = "${get_env("TF_VAR_storage_account_access_key", "empty")}"
  }
}
