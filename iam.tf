# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

data "azurerm_user_assigned_identity" "uai" {
  count               = var.aks_identity == "uai" ? (var.aks_uai_name == null ? 0 : 1) : 0
  name                = var.aks_uai_name
  resource_group_name = local.network_rg.name
}

resource "azurerm_user_assigned_identity" "uai" {
  count               = var.aks_identity == "uai" ? (var.aks_uai_name == null ? 1 : 0) : 0
  name                = "${var.prefix}-aks-identity"
  resource_group_name = local.aks_rg.name
  location            = var.location
  tags                = var.tags
}
