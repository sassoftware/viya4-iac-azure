# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

terraform {

  required_version = ">= 1.4.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.54.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.38.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    # template = {
    #   source  = "hashicorp/template"
    #   version = "2.2.0"
    # }
    tls = {
      source  = "hashicorp/tls"
      version = "3.4.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}
