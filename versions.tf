terraform {
  required_version = ">= 0.13.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.47.0"
    }
    azureread = {
      source  = "hashicorp/azuread"
      version = "1.3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.0.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.2"
    }
  }
}