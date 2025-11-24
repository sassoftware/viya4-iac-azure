resource "azurerm_application_gateway" "appgw" {
  # ...existing code...

  ssl_policy {
    policy_type          = "Custom"
    min_protocol_version = var.ssl_min_protocol_version
    cipher_suites        = var.ssl_cipher_suites
  }

  # ...existing code...
}