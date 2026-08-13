// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test a Spot node pool: priority, eviction_policy, and spot_max_price must be
// set correctly on the node pool resource.
func TestPlanSpotNodePool(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "spot-pool"
	variables["node_pools"] = map[string]interface{}{
		"spot": map[string]interface{}{
			"machine_type":              "Standard_D4s_v5",
			"os_disk_size":              200,
			"min_nodes":                 "0",
			"max_nodes":                 "3",
			"max_pods":                  "110",
			"node_taints":               []string{},
			"node_labels":               map[string]interface{}{},
			"community_priority":        "Spot",
			"community_eviction_policy": "Deallocate",
			"community_spot_max_price":  "-1",
		},
	}

	resourceMapName := `module.node_pools["spot"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`

	tests := map[string]helpers.TestCase{
		"priority": {
			Expected:          "Spot",
			ResourceMapName:   resourceMapName,
			AttributeJsonPath: "{$.priority}",
			Message:           "Node pool priority must be Spot",
		},
		"evictionPolicy": {
			Expected:          "Deallocate",
			ResourceMapName:   resourceMapName,
			AttributeJsonPath: "{$.eviction_policy}",
			Message:           "Node pool eviction_policy must be Deallocate",
		},
		"spotMaxPrice": {
			Expected:          "-1",
			ResourceMapName:   resourceMapName,
			AttributeJsonPath: "{$.spot_max_price}",
			Message:           "Node pool spot_max_price must be -1 (no limit)",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
