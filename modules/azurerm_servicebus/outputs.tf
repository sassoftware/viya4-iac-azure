# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "servicebus_hostname" {
  value = azurerm_servicebus_namespace.smb.endpoint
}

output "servicebus_primary_key" {
  value = azurerm_servicebus_namespace_authorization_rule.smb_policy.primary_key
}
