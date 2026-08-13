// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test node_pools_availability_zones with a multi-zone list applied to all node pools.
func TestPlanMultiZoneNodePools(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "multi-zone"
	variables["node_pools_availability_zones"] = []string{"1", "2", "3"}

	tests := map[string]helpers.TestCase{
		"statelessNodePoolMultiZone": {
			Expected:          `["1","2","3"]`,
			ResourceMapName:   `module.node_pools["stateless"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.zones}",
			Message:           "stateless node pool must span zones 1, 2, and 3",
		},
		"statefulNodePoolMultiZone": {
			Expected:          `["1","2","3"]`,
			ResourceMapName:   `module.node_pools["stateful"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.zones}",
			Message:           "stateful node pool must span zones 1, 2, and 3",
		},
		"casNodePoolMultiZone": {
			Expected:          `["1","2","3"]`,
			ResourceMapName:   `module.node_pools["cas"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]`,
			AttributeJsonPath: "{$.zones}",
			Message:           "cas node pool must span zones 1, 2, and 3",
		},
		// AKS default node pool uses default_nodepool_availability_zones, not node_pools_availability_zones
		"defaultNodePoolZones": {
			Expected:          "nil",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].zones}",
			AssertFunction:    assert.NotEqual,
			Message:           "AKS default node pool zones must still be set",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
