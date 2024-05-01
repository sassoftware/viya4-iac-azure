# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

terraform {

  required_version = ">= 1.7.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.92.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.47"
    }
    external = {
      source  = "hashicorp/external"
      version = "~>2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~>3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~>2.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.25"
    }
  }
}
