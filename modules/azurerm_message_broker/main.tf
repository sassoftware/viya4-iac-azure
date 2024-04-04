# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Azure Service Bus
# - https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview
# - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace
# - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule

resource "azurerm_servicebus_namespace" "message_broker" {
  name                = "${var.prefix}-message-broker"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.message_broker_sku
  capacity            = var.message_broker_capacity

  tags = var.tags
}

resource "azurerm_servicebus_namespace_authorization_rule" "message_broker_config" {
  name         = var.message_broker_name
  namespace_id = azurerm_servicebus_namespace.message_broker.id

  listen = true
  send   = true
  manage = true
}
