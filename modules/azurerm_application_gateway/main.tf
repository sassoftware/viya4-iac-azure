resource "azurerm_public_ip" "appgw" {
  count               = var.create_app_gateway && var.create_public_ip ? 1 : 0
  name                = "${local.base_name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create default WAF policy (always Prevention mode for security)
resource "azurerm_web_application_firewall_policy" "default" {
  count               = var.create_app_gateway && var.enable_waf && var.waf_policy_name == null && var.waf_policy_id == null && (var.app_gateway_config == null || lookup(var.app_gateway_config, "waf_policy", null) == null) ? 1 : 0
  name                = "${local.base_name}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"  # Always Prevention mode for security
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "appgw" {
  count               = var.create_app_gateway ? 1 : 0
  name                = local.base_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name     = var.enable_waf ? "WAF_v2" : var.sku_name
    tier     = var.enable_waf ? "WAF_v2" : var.sku_tier
    capacity = var.enable_autoscaling ? null : var.sku_capacity
  }

  dynamic "autoscale_configuration" {
    for_each = var.enable_autoscaling && var.autoscale_configuration != null ? [var.autoscale_configuration] : []
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = lookup(autoscale_configuration.value, "max_capacity", null)
    }
  }

  dynamic "identity" {
    for_each = local.identity_list != null && length(local.identity_list) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = local.identity_list
    }
  }

  gateway_ip_configuration {
    name      = "${local.base_name}-gateway-ip-configuration"
    subnet_id = local.subnet_id
  }

  dynamic "frontend_port" {
    for_each = local.frontend_ports_list
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  frontend_ip_configuration {
    name                 = "${local.base_name}-frontend-ip-configuration"
    public_ip_address_id = local.public_ip_id
  }

  dynamic "backend_address_pool" {
    for_each = local.backend_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = lookup(backend_address_pool.value, "fqdns", null)
      ip_addresses = lookup(backend_address_pool.value, "ip_addresses", null)
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = local.backend_trusted_root_certs
    content {
      name                = trusted_root_certificate.value.name
      data                = trusted_root_certificate.value.data
      key_vault_secret_id = trusted_root_certificate.value.key_vault_secret_id
    }
  }

  dynamic "backend_http_settings" {
    for_each = local.backend_http_config
    content {
      name                  = backend_http_settings.value.name
      cookie_based_affinity = lookup(backend_http_settings.value, "cookie_based_affinity", "Disabled")
      port                  = backend_http_settings.value.port
      protocol              = backend_http_settings.value.protocol
      request_timeout       = lookup(backend_http_settings.value, "request_timeout", 60)
      probe_name            = lookup(backend_http_settings.value, "probe_name", null)
      host_name             = lookup(backend_http_settings.value, "host_name", null)
      trusted_root_certificate_names = lookup(backend_http_settings.value, "trusted_root_certificate_names", null)
    }
  }

  dynamic "ssl_certificate" {
    for_each = local.ssl_certs
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "http_listener" {
    for_each = local.http_listeners_list
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = "${local.base_name}-frontend-ip-configuration"
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      ssl_certificate_name           = lookup(http_listener.value, "ssl_certificate_name", null)
      host_name                      = lookup(http_listener.value, "host_name", null)
      require_sni                    = lookup(http_listener.value, "require_sni", null)
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.routing_rules_list
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = request_routing_rule.value.rule_type
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = lookup(request_routing_rule.value, "backend_address_pool_name", null)
      backend_http_settings_name = lookup(request_routing_rule.value, "backend_http_settings_name", null)
      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_configuration_name", null)
      priority                   = request_routing_rule.value.priority
    }
  }

  dynamic "probe" {
    for_each = local.health_probes_list
    content {
      name                = probe.value.name
      protocol            = probe.value.protocol
      path                = probe.value.path
      host                = lookup(probe.value, "host", "127.0.0.1")
      interval            = lookup(probe.value, "interval", 30)
      timeout             = lookup(probe.value, "timeout", 30)
      unhealthy_threshold = lookup(probe.value, "unhealthy_threshold", 3)
    }
  }

  # ENFORCED SAS CRYPTOGRAPHY STANDARD COMPLIANCE - NON-OVERRIDABLE
  # 
  # Security Posture:
  # ✅ Enforces: TLS 1.2 minimum (blocks TLS 1.0 and TLS 1.1)
  # ✅ Supports: TLS 1.3 (via CustomV2 policy type)
  # ✅ Blocks: All CBC mode ciphers (padding oracle vulnerabilities)
  # ✅ Blocks: 3DES ciphers (SWEET32 attack - CVE-2016-2183)
  # ✅ Blocks: RSA key exchange (no forward secrecy)
  # ✅ Only allows: ECDHE + AES-GCM (authenticated encryption with forward secrecy)
  #
  # SAS Cryptography Standard Compliance:
  # TLS 1.2 Ciphers:
  # - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (AES-256 + SHA-384)
  # - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (AES-128 + SHA-256)
  # TLS 1.3 Ciphers (automatically supported with CustomV2):
  # - TLS_AES_256_GCM_SHA384
  # - TLS_AES_128_GCM_SHA256
  #
  # Note: TLS 1.3 ciphers are not explicitly listed but are enabled
  # automatically when using policy_type = "CustomV2" and min_protocol_version includes TLS 1.3
  #
  # Certificate Requirements:
  # - RSA keys must be 3072-bit or larger
  # - ECDSA with P-384 curve (if supported)
  ssl_policy {
    policy_type          = "CustomV2"
    min_protocol_version = "TLSv1_2"
    cipher_suites = [
      "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
    ]
    # TLS 1.3 automatically enables (implicit with CustomV2):
    # - TLS_AES_256_GCM_SHA384 ✅
    # - TLS_AES_128_GCM_SHA256 ✅
    # 
    # NOT available on Azure Application Gateway:
    # - TLS_AES_128_CCM_SHA256 ❌ (Platform limitation)
    # - TLS_AES_128_CCM_8_SHA256 ❌ (Platform limitation)
  }

  firewall_policy_id = local.waf_policy

  lifecycle {
    ignore_changes = [
      tags
    ]
    
    precondition {
      condition     = var.sku_tier == "Standard_v2" || var.sku_tier == "WAF_v2" || var.enable_waf
      error_message = "Application Gateway must use v2 SKU (Standard_v2 or WAF_v2) for enhanced security features."
    }

    # Validate subnet is provided
    precondition {
      condition     = local.subnet_id != null
      error_message = "Subnet must be provided via subnet_name + vnet_name or subnet_id."
    }

    # Validate identity when Key Vault is used
    precondition {
      condition     = !local.uses_key_vault || (local.identity_list != null && length(local.identity_list) > 0)
      error_message = "Identity is automatically created when using Key Vault certificates. If you want to use an existing identity, provide identity_name or identity_ids."
    }
  }
}