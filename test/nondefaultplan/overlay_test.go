// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test Azure CNI Overlay mode: network_plugin=azure with network_plugin_mode=overlay.
// Overlay mode requires pod_cidr to be set on the AKS network profile, unlike plain azure CNI.
func TestPlanAzureCniOverlay(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "cni-overlay"
	variables["aks_network_plugin"] = "azure"
	variables["aks_network_plugin_mode"] = "overlay"

	tests := map[string]helpers.TestCase{
		"networkPlugin": {
			Expected:          "azure",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.network_profile[0].network_plugin}",
		},
		"networkPluginMode": {
			Expected:          "overlay",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.network_profile[0].network_plugin_mode}",
			Message:           "network_plugin_mode must be overlay",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
