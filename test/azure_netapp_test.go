package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test the default variables when using the sample-input-defaults.tfvars file
// with storage_type set to "ha". This should engage the Azure NetApp Files module,
// with the default values as tested herein.
func TestAzureNetApp(t *testing.T) {
	tests := map[string]testCase{
		"accountExists": {
			expected:          `nil`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_account.anf",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"poolExists": {
			expected:          `nil`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"poolServiceLevel": {
			expected:          `Premium`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			attributeJsonPath: "{$.service_level}",
		},
		"poolSize": {
			expected:          `4`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			attributeJsonPath: "{$.size_in_tb}",
		},
		"volumeExists": {
			expected:          `nil`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"volumeProtocols": {
			expected:          `["NFSv4.1"]`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$.protocols}",
		},
		"volumeServiceLevel": {
			expected:          `Premium`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$.service_level}",
		},
		"volumePath": {
			expected:          `export`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$.volume_path}",
			assertFunction:    assert.Contains,
		},
		"volumeNetworkFeatures": {
			expected:          `Basic`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$.network_features}",
		},
		"subnetExists": {
			expected:          `nil`,
			resourceMapName:   "module.vnet.azurerm_subnet.subnet[\"netapp\"]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
	}

	// Prepare to generate the plan
	varsFilePath := "../examples/sample-input-defaults.tfvars"
	variables := getPlanVars(t, varsFilePath)
	variables["storage_type"] = "ha"

	// Generate the plan
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	// Run the tests
	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}
