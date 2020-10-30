variable "create_postgres" {
  description = "Boolean flag to create Azure Postgres DB"
  default     = true
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the PostgreSQL Server. Changing this forces a new resource to be created."
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

variable "server_name" {
  description = "Specifies the name of the PostgreSQL Server. Changing this forces a new resource to be created."
}

variable "postgres_sku_name" {
  description = "Specifies the SKU Name for this PostgreSQL Server. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen4_1, GP_Gen5_8)."
  default     = "GP_Gen5_32"
}

variable "postgres_storage_mb" {
  description = "Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs."
  default     = 51200
}

variable "postgres_backup_retention_days" {
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  default     = 7
}

variable "postgres_geo_redundant_backup_enabled" {
  description = "Enable Geo-redundant or not for server backup. Not supported for the basic tier."
  default     = false
}

variable "postgres_administrator_login" {
  description = "The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created."
}

variable "postgres_administrator_password" {
  description = "The Password associated with the postgres_administrator_login for the PostgreSQL Server."
}

variable "postgres_server_version" {
  description = "Specifies the version of PostgreSQL to use. Valid values are 9.5, 9.6, and 10.0. Changing this forces a new resource to be created."
  default     = "11"
}

variable "postgres_ssl_enforcement_enabled" {
  description = "Specifies if SSL should be enforced on connections."
  default     = true
}

variable "postgres_db_names" {
  description = "The list of names of the PostgreSQL Database, which needs to be a valid PostgreSQL identifier. Changing this forces a new resource to be created."
  default     = []
}

variable "postgres_db_charset" {
  description = "Specifies the Charset for the PostgreSQL Database, which needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created."
  default     = "UTF8"
}

variable "postgres_db_collation" {
  description = "Specifies the Collation for the PostgreSQL Database, which needs to be a valid PostgreSQL Collation. Note that Microsoft uses different notation - en-US instead of en_US. Changing this forces a new resource to be created."
  default     = "English_United States.1252"
}

variable "postgres_firewall_rule_prefix" {
  description = "Specifies prefix for firewall rule names."
  default     = "firewall-"
}

variable "postgres_firewall_rules" {
  description = "The list of maps, describing firewall rules"
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = []
}

variable "postgres_vnet_rule_prefix" {
  description = "Specifies prefix for vnet rule names."
  default     = "postgresql-vnet-rule-"
}

variable "postgres_vnet_rules" {
  description = "The list of maps, describing vnet rules."
  type = list(object({
    name      = string
    subnet_id = string
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to set on every taggable resources. Empty by default."
  type        = map
  default     = {}
}

variable "postgres_configurations" {
  description = "A map with PostgreSQL configurations to enable."
  type        = map
  default     = {}
}
