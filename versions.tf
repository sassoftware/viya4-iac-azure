# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

terraform {

  required_version = ">= 1.6.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.81.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.46.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
}
