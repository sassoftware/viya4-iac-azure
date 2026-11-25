// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test AKS private cluster configuration when cluster_api_mode=private.
func TestPlanPrivateCluster(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "private-cluster"
	variables["cluster_api_mode"] = "private"

	tests := map[string]helpers.TestCase{
		"privateClusterEnabled": {
			Expected:          "true",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.private_cluster_enabled}",
			Message:           "private_cluster_enabled must be true when cluster_api_mode=private",
		},
		"privateDnsZoneId": {
			Expected:          "System",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.private_dns_zone_id}",
			Message:           "private_dns_zone_id must be System when no custom DNS zone is provided",
		},
		// api_server_access_profile block is absent because endpoint access CIDRs are forced to [] for private clusters
		"apiServerAccessProfileAbsent": {
			Expected:          "[]",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.api_server_access_profile}",
			Message:           "api_server_access_profile must be absent for a private cluster",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
