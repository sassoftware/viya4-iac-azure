terraform {

  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.43.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.33.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.17.0"
    }
  }
}
