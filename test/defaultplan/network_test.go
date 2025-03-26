// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"
)

func TestPlanNetwork(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"vnetTest": {
			Expected:          `["192.168.0.0/16"]`,
			ResourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
			AttributeJsonPath: "{$.address_space}",
		},
		"vnetSubnetTest": {
			Expected:          "",
			ResourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
			AttributeJsonPath: "{$.subnet[0].name}",
		},
		"clusterEgressTypeTest": {
			Expected:          "loadBalancer",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.network_profile[0].outbound_type}",
		},
		"networkPluginTest": {
			Expected:          "kubenet",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.network_profile[0].network_plugin}",
		},
		"aksNetworkPolicyTest": {
			Expected:          "",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.expressions.aks_network_policy.reference[0]}",
		},
		"aksNetworkPluginModeTest": {
			Expected:          "",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.expressions.aks_network_plugin_mode.reference[0]}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
