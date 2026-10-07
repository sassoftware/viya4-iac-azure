// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test that enabling workload identity sets both OIDC and workload identity flags on the AKS resource.
func TestPlanWorkloadIdentity(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "workload-identity"
	variables["enable_workload_identity"] = true

	tests := map[string]helpers.TestCase{
		"oidcIssuerEnabled": {
			Expected:          "true",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.oidc_issuer_enabled}",
			Message:           "oidc_issuer_enabled must be true when enable_workload_identity=true",
		},
		"workloadIdentityEnabled": {
			Expected:          "true",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.workload_identity_enabled}",
			Message:           "workload_identity_enabled must be true when enable_workload_identity=true",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
