variable "create_app_gateway" {
  description = "Create Application Gateway resources"
  type        = bool
  default     = true
}

variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "name" {
  description = "Name override (uses prefix if not set)"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
}

variable "enable_waf" {
  description = "Enable WAF (creates default policy in Prevention mode)"
  type        = bool
  default     = true
}

variable "sku_name" {
  description = "SKU name"
  type        = string
  default     = "Standard_v2"
}

variable "sku_tier" {
  description = "SKU tier"
  type        = string
  default     = "Standard_v2"
}

variable "sku_capacity" {
  description = "SKU capacity"
  type        = number
  default     = 2
}

variable "create_public_ip" {
  description = "Create public IP"
  type        = bool
  default     = true
}

variable "public_ip_address_id" {
  description = "Existing public IP ID"
  type        = string
  default     = null
}

variable "waf_policy_id" {
  description = "Custom WAF policy ID"
  type        = string
  default     = null
}

variable "waf_policy_name" {
  description = "WAF policy name (not used - removed)"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "User-assigned identity IDs"
  type        = list(string)
  default     = null
}

variable "app_gateway_config" {
  description = "Application Gateway configuration"
  type = object({
    backend_host_name = optional(string)
    backend_address_pool_fqdn = optional(list(string))
    backend_trusted_root_certificate = optional(list(object({
      name             = string
      data             = optional(string)      # Local file path (Option 1)
      certificate_name = optional(string)      # Certificate name in Key Vault (Option 2)
    })))
    ssl_certificate = optional(list(object({
      name             = string
      data             = optional(string)      # Local file path (Option 1)
      password         = optional(string)      # Required with data
      certificate_name = optional(string)      # Certificate name in Key Vault (Option 2)
    })))
    waf_policy   = optional(string)
    identity_ids = optional(list(string))
  })
  default   = null
  sensitive = true
}

variable "key_vault_name" {
  description = "Key Vault name (for certificate lookup by name)"
  type        = string
  default     = null
}

variable "key_vault_resource_group_name" {
  description = "Key Vault resource group name (defaults to main resource group)"
  type        = string
  default     = null
}