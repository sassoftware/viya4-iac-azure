// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test that a custom tags map propagates to the AKS cluster resource.
func TestPlanTagsPropagation(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "tags-test"
	variables["tags"] = map[string]interface{}{
		"env":   "test",
		"owner": "testuser",
	}

	tests := map[string]helpers.TestCase{
		"aksClusterTagEnv": {
			Expected:          "test",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.tags.env}",
			Message:           "AKS cluster must carry the env tag",
		},
		"aksClusterTagOwner": {
			Expected:          "testuser",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.tags.owner}",
			Message:           "AKS cluster must carry the owner tag",
		},
		"vnetTagEnv": {
			Expected:          "test",
			ResourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
			AttributeJsonPath: "{$.tags.env}",
			Message:           "VNet must carry the env tag",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
