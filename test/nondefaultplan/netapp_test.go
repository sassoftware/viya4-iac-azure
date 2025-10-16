// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test the default variables when using the sample-input-defaults.tfvars file
// with storage_type set to "ha". This should engage the Azure NetApp Files module,
// with the default values as tested herein.
func TestPlanNetApp(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "net-app"
	variables["storage_type"] = "ha"

	tests := map[string]helpers.TestCase{
		"accountExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_account.anf",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"poolExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"poolServiceLevel": {
			Expected:          `Premium`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			AttributeJsonPath: "{$.service_level}",
		},
		"poolSize": {
			Expected:          `4`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			AttributeJsonPath: "{$.size_in_tb}",
		},
		"volumeExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"volumeProtocols": {
			Expected:          `["NFSv4.1"]`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			AttributeJsonPath: "{$.protocols}",
		},
		"volumeServiceLevel": {
			Expected:          `Premium`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			AttributeJsonPath: "{$.service_level}",
		},
		"volumePath": {
			Expected:          `export`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			AttributeJsonPath: "{$.volume_path}",
			AssertFunction:    assert.Contains,
		},
		"volumeNetworkFeatures": {
			Expected:          `Basic`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			AttributeJsonPath: "{$.network_features}",
		},
		"subnetExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.vnet.azurerm_subnet.subnet[\"netapp\"]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"communityNetappZone": {
			Expected:          `1`,
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			AttributeJsonPath: "{$.zone}",
			AssertFunction:    assert.Equal,
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
