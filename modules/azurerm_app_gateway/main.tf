# Copyright © 2020-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
## https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/web_application_firewall_policy

locals {
  backend_address_pool_name      = "${var.prefix}-backend-pool"
  frontend_port_name             = "${var.prefix}-frontend-port"
  frontend_ip_configuration_name = "${var.prefix}-frontend-ip"
  http_setting_name              = "${var.prefix}-backend-setting"
  listener_name                  = "${var.prefix}-listener"
  request_routing_rule_name      = "${var.prefix}-routing-rule"
}

resource "azurerm_public_ip" "gateway_ip" {
  name                = "${var.prefix}-gateway-public_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.backend_host_name == null ? "${var.prefix}-appgateway" : null
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  count = var.waf_policy_enabled ? 1 : 0

  name                = "${var.prefix}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dynamic "custom_rules" {
    for_each = var.waf_policy_config.custom_rules
    content {
      name      = custom_rules.value.name
      priority  = custom_rules.value.priority
      rule_type = custom_rules.value.rule_type
      action    = custom_rules.value.action
      dynamic "match_conditions" {
        for_each = custom_rules.value.match_conditions
        content {
          operator           = match_conditions.value.operator
          negation_condition = match_conditions.value.negation_condition
          match_values       = match_conditions.value.match_values
          dynamic "match_variables" {
            for_each = match_conditions.value.match_variables
            content {
              variable_name = match_variables.value.variable_name
            }
          }
        }
      }
    }
  }

  dynamic "policy_settings" {
    for_each = var.waf_policy_config.policy_settings != null ? [var.waf_policy_config.policy_settings] : []
    content {
      enabled                     = policy_settings.value.enabled
      mode                        = policy_settings.value.mode
      request_body_check          = policy_settings.value.request_body_check
      file_upload_limit_in_mb     = policy_settings.value.file_upload_limit_in_mb
      max_request_body_size_in_kb = policy_settings.value.max_request_body_size_in_kb
    }
  }

  managed_rules {
    dynamic "exclusion" {
      for_each = var.waf_policy_config.managed_rules.exclusion
      content {
        match_variable          = exclusion.value.match_variable
        selector                = exclusion.value.selector
        selector_match_operator = exclusion.value.selector_match_operator
        dynamic "excluded_rule_set" {
          for_each = exclusion.value.excluded_rule_set
          content {
            type    = excluded_rule_set.value.type
            version = excluded_rule_set.value.version
            dynamic "rule_group" {
              for_each = excluded_rule_set.value.rule_group
              content {
                rule_group_name = rule_group.value.rule_group_name
                excluded_rules  = rule_group.value.excluded_rules
              }
            }
          }
        }
      }
    }

    dynamic "managed_rule_set" {
      for_each = var.waf_policy_config.managed_rules.managed_rule_set
      content {
        type    = managed_rule_set.value.type
        version = managed_rule_set.value.version
        dynamic "rule_group_override" {
          for_each = managed_rule_set.value.rule_group_override
          content {
            rule_group_name = rule_group_override.value.rule_group_name
            dynamic "rule" {
              for_each = rule_group_override.value.rule
              content {
                id      = rule.value.id
                enabled = rule.value.enabled
                action  = rule.value.action
              }
            }
          }
        }
      }
    }
  }
}


resource "azurerm_application_gateway" "appgateway" {
  name                              = "${var.prefix}-appgateway"
  resource_group_name               = var.resource_group_name
  location                          = var.location
  firewall_policy_id                = var.waf_policy_enabled ? azurerm_web_application_firewall_policy.waf_policy[0].id : null
  force_firewall_policy_association = var.waf_policy_enabled ? true : false

  sku {
    name     = var.waf_policy_enabled ? "WAF_v2" : var.sku
    tier     = var.waf_policy_enabled ? "WAF_v2" : "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${var.prefix}-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = var.port
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway_ip.id
  }

  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = var.backend_address_pool_fqdn != null ? length(var.backend_address_pool_fqdn) != 0 ? var.backend_address_pool_fqdn : null : null
  }

  dynamic "trusted_root_certificate" {
    for_each = var.backend_trusted_root_certificate == null ? [] : var.backend_trusted_root_certificate

    content {
      name                = try(trusted_root_certificate.value.name, null)
      data                = try(trusted_root_certificate.value.data, null) != null ? filebase64(trusted_root_certificate.value.data) : null
      key_vault_secret_id = try(trusted_root_certificate.value.data, null) != null ? null : trusted_root_certificate.value.key_vault_secret_id
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificate == null ? [] : var.ssl_certificate

    content {
      name                = try(ssl_certificate.value.name, null)
      data                = try(ssl_certificate.value.data, null) != null ? filebase64(ssl_certificate.value.data) : null
      password            = try(ssl_certificate.value.password, null)
      key_vault_secret_id = try(ssl_certificate.value.data, null) != null ? null : ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "identity" {
    for_each = var.identity_ids == null ? [] : [1]

    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  backend_http_settings {
    name                           = local.http_setting_name
    cookie_based_affinity          = "Disabled"
    port                           = var.port
    protocol                       = var.protocol
    request_timeout                = 60
    probe_name                     = var.probe != null ? try(var.probe[0].name, "default-probe") : null
    host_name                      = var.backend_host_name == null ? azurerm_public_ip.gateway_ip.fqdn : var.backend_host_name
    trusted_root_certificate_names = var.backend_trusted_root_certificate == null ? null : [var.backend_trusted_root_certificate[0].name]
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = var.protocol
    ssl_certificate_name           = var.ssl_certificate == null ? null : var.ssl_certificate[0].name
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
  }

  dynamic "probe" {
    for_each = var.probe != null ? var.probe : []

    content {
      name                                      = probe.value.name
      interval                                  = 60
      protocol                                  = var.protocol
      path                                      = probe.value.path
      timeout                                   = 30
      unhealthy_threshold                       = 3
      pick_host_name_from_backend_http_settings = true
    }
  }

  tags = var.tags

  depends_on = [azurerm_web_application_firewall_policy.waf_policy]
}
