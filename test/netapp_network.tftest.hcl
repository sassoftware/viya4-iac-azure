# Copyright © 2026, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Run from the repository root: terraform test -test-directory=test
mock_provider "azurerm" {
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-netapp-vnet"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-netapp-vnet/subnets/test-netapp-subnet"
    }
  }
  mock_resource "azurerm_netapp_volume" {
    defaults = {
      id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.NetApp/netAppAccounts/test-netappaccount/capacityPools/test-netapppool/volumes/test-netappvolume"
      mount_ip_addresses = ["172.31.0.4"]
    }
  }
}
mock_provider "azuread" {}
mock_provider "kubernetes" {}
mock_provider "external" {}
mock_provider "local" {}
mock_provider "null" {}
mock_provider "tls" {}
mock_provider "cloudinit" {}

override_module {
  target = module.aks
  outputs = {
    host                   = "https://aks.example.test"
    client_key             = ""
    client_certificate     = ""
    cluster_ca_certificate = ""
    cluster_username       = "test"
    cluster_password       = ""
    cluster_public_ip      = "192.0.2.1"
    cluster_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ContainerService/managedClusters/test"
    name                   = "test-aks"
  }
}

override_module {
  target  = module.kubeconfig
  outputs = { kube_config = "" }
}

override_data {
  target = data.external.git_hash
  values = { result = { "git-hash" = "test" } }
}

override_data {
  target = data.external.iac_tooling_version
  values = {
    result = {
      terraform_version   = "test"
      terraform_revision  = "test"
      provider_selections = "test"
      terraform_outdated  = "false"
    }
  }
}

override_data {
  target = data.azurerm_subscription.current
  values = {
    id           = "/subscriptions/00000000-0000-0000-0000-000000000000"
    tenant_id    = "00000000-0000-0000-0000-000000000000"
    display_name = "test"
  }
}

override_data {
  target = data.azurerm_virtual_network.netapp_clients[0]
  values = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
    name = "test-vnet"
  }
}

override_data {
  target = data.azurerm_subnet.aks_ipv6[0]
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-aks-subnet"
    address_prefixes = ["192.168.0.0/23", "fd00:1234:5678::/64"]
  }
}

override_data {
  target = data.azurerm_subnet.misc_ipv6[0]
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-misc-subnet"
    address_prefixes = ["192.168.2.0/24", "fd00:1234:5678:1::/64"]
  }
}

variables {
  prefix                  = "test"
  subscription_id         = "00000000-0000-0000-0000-000000000000"
  tenant_id               = "00000000-0000-0000-0000-000000000000"
  enable_ipv6             = true
  storage_type            = "ha"
  netapp_network_features = "Standard"
  create_jump_vm          = false
  node_pools              = {}
}

run "dual_stack_ha" {
  command = apply

  assert {
    condition     = azurerm_virtual_network.netapp_ipv4[0].address_space == toset(["172.31.0.0/24"])
    error_message = "NetApp must be hosted in an IPv4-only VNet."
  }

  assert {
    condition = (
      azurerm_subnet.netapp_ipv4[0].virtual_network_name == azurerm_virtual_network.netapp_ipv4[0].name &&
      azurerm_subnet.netapp_ipv4[0].address_prefixes == tolist(["172.31.0.0/24"]) &&
      azurerm_subnet.netapp_ipv4[0].delegation[0].service_delegation[0].name == "Microsoft.Netapp/volumes"
    )
    error_message = "NetApp requires a delegated subnet in its dedicated IPv4 VNet."
  }

  assert {
    condition = (
      azurerm_virtual_network_peering.aks_to_netapp[0].remote_virtual_network_id == azurerm_virtual_network.netapp_ipv4[0].id &&
      azurerm_virtual_network_peering.netapp_to_aks[0].remote_virtual_network_id == data.azurerm_virtual_network.netapp_clients[0].id &&
      azurerm_virtual_network_peering.aks_to_netapp[0].allow_virtual_network_access &&
      azurerm_virtual_network_peering.netapp_to_aks[0].allow_virtual_network_access
    )
    error_message = "Both VNet peerings must permit client access."
  }

  assert {
    condition = (
      jsondecode(output.rwx_filestore_config).virtualNetwork == azurerm_virtual_network.netapp_ipv4[0].name &&
      jsondecode(output.rwx_filestore_config).subnet.id == azurerm_subnet.netapp_ipv4[0].id &&
      jsondecode(output.rwx_filestore_config).defaults.exportRule == "192.168.0.0/16"
    )
    error_message = "Storage configuration must reference the IPv4 NetApp network and permit AKS clients."
  }
}

run "dual_stack_replication" {
  command = apply

  variables {
    netapp_enable_cross_zone_replication = true
    netapp_replication_zone              = "2"
    netapp_vnet_address_space            = "172.30.0.0/24"
  }

  assert {
    condition     = output.netapp_dns_hostname == "nfs.sas-viya.internal"
    error_message = "Dual-stack cross-zone replication must expose its stable DNS hostname."
  }

  assert {
    condition     = azurerm_subnet.netapp_ipv4[0].address_prefixes == tolist(["172.30.0.0/24"])
    error_message = "The dedicated NetApp subnet must honor a custom IPv4 range."
  }
}

run "ipv4_ha_unchanged" {
  command = apply

  variables {
    enable_ipv6 = false
  }

  assert {
    condition = (
      length(azurerm_virtual_network.netapp_ipv4) == 0 &&
      length(azurerm_subnet.netapp_ipv4) == 0 &&
      length(azurerm_virtual_network_peering.aks_to_netapp) == 0 &&
      length(azurerm_virtual_network_peering.netapp_to_aks) == 0 &&
      jsondecode(output.rwx_filestore_config).virtualNetwork == "test-vnet"
    )
    error_message = "IPv4 HA must continue using the original VNet without peerings."
  }
}

run "dual_stack_without_ha" {
  command = apply

  variables {
    storage_type = "none"
  }

  assert {
    condition = (
      length(azurerm_virtual_network.netapp_ipv4) == 0 &&
      length(azurerm_subnet.netapp_ipv4) == 0 &&
      length(azurerm_virtual_network_peering.aks_to_netapp) == 0 &&
      length(azurerm_virtual_network_peering.netapp_to_aks) == 0 &&
      output.rwx_filestore_config == null
    )
    error_message = "Deployments without HA storage must not create NetApp networking."
  }
}

run "overlapping_storage_network" {
  command = plan

  variables {
    netapp_vnet_address_space = "192.168.3.0/24"
  }

  expect_failures = [azurerm_virtual_network.netapp_ipv4]
}

run "invalid_storage_network" {
  command = plan

  variables {
    netapp_vnet_address_space = "fd00:1234:5678::/64"
  }

  expect_failures = [var.netapp_vnet_address_space]
}

run "storage_network_contains_aks" {
  command = plan

  variables {
    netapp_vnet_address_space = "192.168.0.0/15"
  }

  expect_failures = [azurerm_virtual_network.netapp_ipv4]
}

run "storage_network_too_small" {
  command = plan

  variables {
    netapp_vnet_address_space = "172.31.0.0/30"
  }

  expect_failures = [var.netapp_vnet_address_space]
}
