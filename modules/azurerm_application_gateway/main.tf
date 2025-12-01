resource "azurerm_application_gateway" "appgw" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.sku_capacity
  }

  gateway_ip_configuration {
    name      = "${var.name}-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "${var.name}-frontend-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${var.name}-frontend-ip-configuration"
    public_ip_address_id = var.public_ip_address_id
  }

  backend_address_pool {
    name = "${var.name}-backend-pool"
  }

  backend_http_settings {
    name                  = "${var.name}-backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${var.name}-http-listener"
    frontend_ip_configuration_name = "${var.name}-frontend-ip-configuration"
    frontend_port_name             = "${var.name}-frontend-port"
    protocol                       = "Https"
  }

  request_routing_rule {
    name                       = "${var.name}-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "${var.name}-http-listener"
    backend_address_pool_name  = "${var.name}-backend-pool"
    backend_http_settings_name = "${var.name}-backend-http-settings"
    priority                   = 100
  }

  ssl_policy {
    policy_type          = "Custom"
    min_protocol_version = var.ssl_min_protocol_version
    cipher_suites        = var.ssl_cipher_suites
  }
}