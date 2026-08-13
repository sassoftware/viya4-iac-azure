// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test non-default node_os_upgrade_channel values.

func TestPlanNodeOsUpgradeChannelSecurityPatch(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "os-upgrade-secpatch"
	variables["community_node_os_upgrade_channel"] = "SecurityPatch"

	tests := map[string]helpers.TestCase{
		"nodeOsUpgradeChannelSecurityPatch": {
			Expected:          "SecurityPatch",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.node_os_upgrade_channel}",
			Message:           "node_os_upgrade_channel must be SecurityPatch",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

func TestPlanNodeOsUpgradeChannelNone(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "os-upgrade-none"
	variables["community_node_os_upgrade_channel"] = "None"

	tests := map[string]helpers.TestCase{
		"nodeOsUpgradeChannelNone": {
			Expected:          "None",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.node_os_upgrade_channel}",
			Message:           "node_os_upgrade_channel must be None",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test AKS Standard tier.
func TestPlanAksSkuStandard(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "aks-sku-standard"
	variables["aks_cluster_sku_tier"] = "Standard"

	tests := map[string]helpers.TestCase{
		"skuTierStandard": {
			Expected:          "Standard",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.sku_tier}",
			Message:           "AKS sku_tier must be Standard",
		},
		"supportPlan": {
			Expected:          "KubernetesOfficial",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.support_plan}",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test AKS Premium tier paired with AKSLongTermSupport, which is the required combination.
func TestPlanAksPremiumLts(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "aks-premium-lts"
	variables["aks_cluster_sku_tier"] = "Premium"
	variables["cluster_support_tier"] = "AKSLongTermSupport"

	tests := map[string]helpers.TestCase{
		"skuTierPremium": {
			Expected:          "Premium",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.sku_tier}",
			Message:           "AKS sku_tier must be Premium",
		},
		"supportPlanLts": {
			Expected:          "AKSLongTermSupport",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.support_plan}",
			Message:           "support_plan must be AKSLongTermSupport when sku_tier=Premium",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test that fips_enabled=true propagates to the AKS default node pool and additional node pools.
func TestPlanFipsEnabled(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "fips-enabled"
	variables["fips_enabled"] = true

	tests := map[string]helpers.TestCase{
		"defaultNodePoolFipsEnabled": {
			Expected:          "true",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].fips_enabled}",
			Message:           "Default node pool must have fips_enabled=true",
		},
		"statelessNodePoolFipsEnabled": {
			Expected:          "true",
			ResourceMapName:   `module.node_pools["stateless"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.fips_enabled}",
			Message:           "stateless node pool must have fips_enabled=true",
		},
		"statefulNodePoolFipsEnabled": {
			Expected:          "true",
			ResourceMapName:   `module.node_pools["stateful"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.fips_enabled}",
			Message:           "stateful node pool must have fips_enabled=true",
		},
		"casNodePoolFipsEnabled": {
			Expected:          "true",
			ResourceMapName:   `module.node_pools["cas"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.fips_enabled}",
			Message:           "cas node pool must have fips_enabled=true",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test that aks_cluster_enable_host_encryption=true propagates to the AKS default node pool
// and additional node pools.
func TestPlanHostEncryption(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "host-encryption"
	variables["aks_cluster_enable_host_encryption"] = true

	tests := map[string]helpers.TestCase{
		"defaultNodePoolHostEncryption": {
			Expected:          "true",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].host_encryption_enabled}",
			Message:           "Default node pool must have host_encryption_enabled=true",
		},
		"statelessNodePoolHostEncryption": {
			Expected:          "true",
			ResourceMapName:   `module.node_pools["stateless"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.host_encryption_enabled}",
			Message:           "stateless node pool must have host_encryption_enabled=true",
		},
		"statefulNodePoolHostEncryption": {
			Expected:          "true",
			ResourceMapName:   `module.node_pools["stateful"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.host_encryption_enabled}",
			Message:           "stateful node pool must have host_encryption_enabled=true",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test User Defined Routing egress type on the AKS network profile.
func TestPlanUserDefinedRouting(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "udr-egress"
	variables["cluster_egress_type"] = "userDefinedRouting"

	tests := map[string]helpers.TestCase{
		"outboundTypeUdr": {
			Expected:          "userDefinedRouting",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.network_profile[0].outbound_type}",
			Message:           "AKS outbound_type must be userDefinedRouting",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
