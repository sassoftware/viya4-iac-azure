// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package test

import (
	"testing"

	"github.com/stretchr/testify/require"
)

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	defaultTests := map[string]testCase{
		"vnetTest": {
			expected:          `["192.168.0.0/16"]`,
			resourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
			attributeJsonPath: "{$.address_space}",
		},
		"nodeVmAdminTest": {
			expected:          "azureuser",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.linux_profile[0].admin_username}",
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range defaultTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}
