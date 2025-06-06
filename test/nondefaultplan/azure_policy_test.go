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
	variables["aks_network_plugin"] = "azure"

	tests := map[string]helpers.TestCase{
		"azurePolicyEnabledTest": {
			Expected:          "true",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_policy_enabled}",
			Message:           "Unexpected azure_policy_enabled value",
		},
		"networkPluginTest": {
			Expected:          "azure",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.network_profile[0].network_plugin}",
		},
		"azurePluginAksPodCidrTest": {
			Expected:        "192.168.0.0/16",
			ResourceMapName: "aks_pod_cidr",
			Retriever:       helpers.RetrieveFromRawPlanOutputChanges,
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
