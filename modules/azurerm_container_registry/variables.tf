variable container_registry_name {}
variable container_registry_rg {}
variable container_registry_location {}

variable create_container_registry {
  default = false
}
variable container_registry_sku {
    description = "The SKU name of the container registry. Possible values are Basic, Standard and Premium"
    default     = "Standard"
}
variable container_registry_admin_enabled {
  default = false
}

# only for Premium SKU
variable container_registry_geo_replica_locs {
  default = null
}

variable container_registry_sp_role {}
