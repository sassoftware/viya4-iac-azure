locals {
  # Resource naming
  base_name = var.prefix != null ? "${var.prefix}-appgw" : var.name

  # Subnet ID (passed directly from main.tf)
  subnet_id = var.subnet_id

  # Process backend trusted root certificates
  backend_trusted_root_certs = var.app_gateway_config != null && lookup(var.app_gateway_config, "backend_trusted_root_certificate", null) != null ? [
    for i, cert in var.app_gateway_config.backend_trusted_root_certificate : {
      name = cert.name
      # Option 1: Local file upload
      data = lookup(cert, "data", null) != null ? filebase64(cert.data) : null
      # Option 2: Key Vault certificate name (auto-fetch secret_id)
      key_vault_secret_id = lookup(cert, "certificate_name", null) != null && lookup(cert, "data", null) == null ? try(data.azurerm_key_vault_certificate.backend_cert[i].secret_id, null) : null
    }
  ] : []

  # Process SSL certificates
  ssl_certs = var.app_gateway_config != null && lookup(var.app_gateway_config, "ssl_certificate", null) != null ? [
    for i, cert in var.app_gateway_config.ssl_certificate : {
      name     = cert.name
      # Option 1: Local file upload
      data     = lookup(cert, "data", null) != null ? filebase64(cert.data) : null
      password = lookup(cert, "password", null)
      # Option 2: Key Vault certificate name (auto-fetch secret_id)
      key_vault_secret_id = lookup(cert, "certificate_name", null) != null && lookup(cert, "data", null) == null ? try(data.azurerm_key_vault_certificate.ssl_cert[i].secret_id, null) : null
    }
  ] : []

  # Auto-detect if Key Vault is being used
  uses_key_vault = (
    anytrue([for cert in local.ssl_certs : lookup(cert, "key_vault_secret_id", null) != null]) ||
    anytrue([for cert in local.backend_trusted_root_certs : lookup(cert, "key_vault_secret_id", null) != null])
  )

  # Smart identity creation: auto-enable if Key Vault is used
  should_create_identity = local.uses_key_vault && var.identity_ids == null

  # Identity resolution
  identity_list = local.should_create_identity && var.create_app_gateway ? [azurerm_user_assigned_identity.appgw[0].id] : var.identity_ids

  # WAF policy resolution
  waf_policy = var.enable_waf && var.create_app_gateway && var.waf_policy_id == null ? azurerm_web_application_firewall_policy.default[0].id : var.waf_policy_id

  # Public IP resolution
  public_ip_id = var.create_public_ip && var.create_app_gateway ? azurerm_public_ip.appgw[0].id : var.public_ip_address_id

  # Backend pools
  backend_pools = var.app_gateway_config != null && lookup(var.app_gateway_config, "backend_address_pool_fqdn", null) != null ? [
    {
      name  = "${local.base_name}-backend-pool"
      fqdns = var.app_gateway_config.backend_address_pool_fqdn
    }
  ] : [{
    name = "${local.base_name}-backend-pool"
  }]

  # Backend HTTP settings
  backend_http_config = var.app_gateway_config != null && lookup(var.app_gateway_config, "backend_host_name", null) != null ? [
    {
      name                           = "${local.base_name}-backend-http-settings"
      port                           = 443
      protocol                       = "Https"
      host_name                      = var.app_gateway_config.backend_host_name
      trusted_root_certificate_names = length(local.backend_trusted_root_certs) > 0 ? [for cert in local.backend_trusted_root_certs : cert.name] : null
    }
  ] : [{
    name     = "${local.base_name}-backend-http-settings"
    port     = 80
    protocol = "Http"
  }]

  # Default frontend ports
  frontend_ports_list = [
    {
      name = "${local.base_name}-https-port"
      port = 443
    },
    {
      name = "${local.base_name}-http-port"
      port = 80
    }
  ]

  # Default HTTP listeners
  http_listeners_list = length(local.ssl_certs) > 0 ? [
    {
      name                 = "${local.base_name}-https-listener"
      frontend_port_name   = "${local.base_name}-https-port"
      protocol             = "Https"
      ssl_certificate_name = local.ssl_certs[0].name
    }
  ] : []

  # Default routing rules
  routing_rules_list = length(local.http_listeners_list) > 0 ? [
    {
      name                       = "${local.base_name}-default-rule"
      rule_type                  = "Basic"
      http_listener_name         = local.http_listeners_list[0].name
      backend_address_pool_name  = local.backend_pools[0].name
      backend_http_settings_name = local.backend_http_config[0].name
      priority                   = 100
    }
  ] : []

  # Default health probes (if backend uses HTTPS)
  health_probes_list = length(local.backend_http_config) > 0 && lookup(local.backend_http_config[0], "protocol", "Http") == "Https" ? [
    {
      name                = "${local.base_name}-health-probe"
      protocol            = "Https"
      path                = "/health"
      host                = lookup(local.backend_http_config[0], "host_name", "127.0.0.1")
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
    }
  ] : []
}