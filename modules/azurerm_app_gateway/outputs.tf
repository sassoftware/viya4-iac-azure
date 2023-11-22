# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "gateway_frontend_ip" {
  value = azurerm_public_ip.gateway_ip.ip_address
}
