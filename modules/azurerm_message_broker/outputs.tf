# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "message_broker_hostname" {
  value = regex("//(.*):", azurerm_servicebus_namespace.mq.endpoint)
}

output "message_broker_primary_key" {
  value = azurerm_servicebus_namespace_authorization_rule.mq_config.primary_key
}
