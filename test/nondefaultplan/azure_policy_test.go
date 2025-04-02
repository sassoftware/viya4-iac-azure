// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test the default variables when using the sample-input-defaults.tfvars file
// with aks_azure_policy_enabled set to "true".
func TestPlanAzurePolicy(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["aks_azure_policy_enabled"] = true

	tests := map[string]helpers.TestCase{
		"azurePolicyEnabledTest": {
			Expected:          "true",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_policy_enabled}",
			Message:           "Unexpected azure_policy_enabled value",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
