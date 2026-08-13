// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test Proximity Placement Group: the PPG resource must exist and node pools must have
// empty availability zones (mutually exclusive with PPG).
func TestPlanProximityPlacementGroup(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "ppg-enabled"
	variables["node_pools_proximity_placement"] = true

	tests := map[string]helpers.TestCase{
		"ppgExists": {
			Expected:          "nil",
			ResourceMapName:   "azurerm_proximity_placement_group.proximity[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "Proximity Placement Group resource must be created when node_pools_proximity_placement=true",
		},
		// When PPG is enabled, availability zones must be empty for node pools
		"statelessNodePoolZonesEmpty": {
			Expected:          "[]",
			ResourceMapName:   `module.node_pools["stateless"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.zones}",
			Message:           "stateless node pool zones must be empty when PPG is enabled",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
