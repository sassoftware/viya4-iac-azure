# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Azure Service Bus
# - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace
# - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule

resource "azurerm_servicebus_namespace" "smb" {
  name                = "${var.prefix}-smb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.servicebus_sku
  capacity            = var.servicebus_capacity

  tags = var.tags
}

resource "azurerm_servicebus_namespace_authorization_rule" "smb_policy" {
  name         = var.servicebus_policy_name
  namespace_id = azurerm_servicebus_namespace.smb.id

  listen = true
  send   = true
  manage = true
}
