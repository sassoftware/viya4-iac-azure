locals {
  # Resource naming
  base_name = var.create_app_gateway ? (var.prefix != null ? "${var.prefix}-appgw" : var.name) : ""

  # Subnet ID
  subnet_id = var.create_app_gateway ? var.subnet_id : null

  # Backend trusted root certificates (only when gateway enabled)
  backend_trusted_root_certs = !var.create_app_gateway ? [] : (var.app_gateway_config != null && lookup(var.app_gateway_config, "backend_trusted_root_certificate", null) != null ? [
    for i, cert in var.app_gateway_config.backend_trusted_root_certificate : {
      name                = cert.name
      data                = lookup(cert, "data", null) != null ? filebase64(cert.data) : null
      key_vault_secret_id = lookup(cert, "certificate_name", null) != null && lookup(cert, "data", null) == null ? try(data.azurerm_key_vault_certificate.backend_cert[i].secret_id, null) : null
    }
  ] : [])

  # SSL certificates (only when gateway enabled)
  ssl_certs = !var.create_app_gateway ? [] : (var.app_gateway_config != null && lookup(var.app_gateway_config, "ssl_certificate", null) != null ? [
    for i, cert in var.app_gateway_config.ssl_certificate : {
      name                = cert.name
      data                = lookup(cert, "data", null) != null ? filebase64(cert.data) : null
      password            = lookup(cert, "password", null)
      key_vault_secret_id = lookup(cert, "certificate_name", null) != null && lookup(cert, "data", null) == null ? try(data.azurerm_key_vault_certificate.ssl_cert[i].secret_id, null) : null
    }
  ] : [])

  # Key Vault usage detection
  uses_key_vault = var.create_app_gateway && (anytrue([for cert in local.ssl_certs : lookup(cert, "key_vault_secret_id", null) != null]) || anytrue([for cert in local.backend_trusted_root_certs : lookup(cert, "key_vault_secret_id", null) != null]))

  # Identity auto-creation
  should_create_identity = var.create_app_gateway && local.uses_key_vault && var.identity_ids == null
  identity_list          = local.should_create_identity ? [azurerm_user_assigned_identity.appgw[0].id] : var.identity_ids

  # WAF and Public IP
  waf_policy   = var.create_app_gateway && var.enable_waf && var.waf_policy_id == null ? azurerm_web_application_firewall_policy.default[0].id : var.waf_policy_id
  public_ip_id = var.create_app_gateway && var.create_public_ip ? azurerm_public_ip.appgw[0].id : var.public_ip_address_id

  # Backend pools
  backend_pools = !var.create_app_gateway ? [] : (var.app_gateway_config != null && lookup(var.app_gateway_config, "backend_address_pool_fqdn", null) != null ? [{
    name  = "${local.base_name}-backend-pool"
    fqdns = var.app_gateway_config.backend_address_pool_fqdn
  }] : [{
    name  = "${local.base_name}-backend-pool"
    fqdns = null
  }])

  # Backend HTTP settings
  backend_http_config = !var.create_app_gateway ? [] : (var.app_gateway_config != null && lookup(var.app_gateway_config, "backend_host_name", null) != null ? [{
    name                           = "${local.base_name}-backend-http-settings"
    port                           = 443
    protocol                       = "Https"
    host_name                      = var.app_gateway_config.backend_host_name
    trusted_root_certificate_names = length(local.backend_trusted_root_certs) > 0 ? [for cert in local.backend_trusted_root_certs : cert.name] : null
  }] : [{
    name     = "${local.base_name}-backend-http-settings"
    port     = 80
    protocol = "Http"
  }])

  # Frontend ports
  frontend_ports_list = !var.create_app_gateway ? [] : [{
    name = "${local.base_name}-https-port"
    port = 443
  }, {
    name = "${local.base_name}-http-port"
    port = 80
  }]

  # HTTP listeners
  http_listeners_list = !var.create_app_gateway ? [] : (length(local.ssl_certs) > 0 ? [{
    name                 = "${local.base_name}-https-listener"
    frontend_port_name   = "${local.base_name}-https-port"
    protocol             = "Https"
    ssl_certificate_name = local.ssl_certs[0].name
  }] : [])

  # Routing rules
  routing_rules_list = !var.create_app_gateway ? [] : (length(local.http_listeners_list) > 0 ? [{
    name                       = "${local.base_name}-default-rule"
    rule_type                  = "Basic"
    http_listener_name         = local.http_listeners_list[0].name
    backend_address_pool_name  = local.backend_pools[0].name
    backend_http_settings_name = local.backend_http_config[0].name
    priority                   = 100
  }] : [])

  # Health probes
  health_probes_list = !var.create_app_gateway ? [] : (length(local.backend_http_config) > 0 && lookup(local.backend_http_config[0], "protocol", "Http") == "Https" ? [{
    name                = "${local.base_name}-health-probe"
    protocol            = "Https"
    path                = "/health"
    host                = lookup(local.backend_http_config[0], "host_name", "127.0.0.1")
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }] : [])
}