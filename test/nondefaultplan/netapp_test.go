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

// Test NetApp cross-zone replication: replica pool, replica volume, private DNS zone,
// and DNS A record must all be created. network_features=Standard is required by the precondition.
func TestPlanNetAppCrossZoneReplication(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "netapp-czr"
	variables["storage_type"] = "ha"
	variables["netapp_enable_cross_zone_replication"] = true
	variables["netapp_network_features"] = "Standard"
	variables["netapp_availability_zone"] = "1"
	variables["netapp_replication_zone"] = "2"
	variables["netapp_size_in_tb"] = 1

	tests := map[string]helpers.TestCase{
		"primaryVolumeNetworkFeaturesStandard": {
			Expected:          "Standard",
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			AttributeJsonPath: "{$.network_features}",
			Message:           "Primary volume network_features must be Standard for CZR",
		},
		"replicaPoolExists": {
			Expected:          "nil",
			ResourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf_replica[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "Replica pool must be created when netapp_enable_cross_zone_replication=true",
		},
		"replicaVolumeExists": {
			Expected:          "nil",
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf_replica[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "Replica volume must be created when netapp_enable_cross_zone_replication=true",
		},
		"privateDnsZoneExists": {
			Expected:          "nil",
			ResourceMapName:   "module.netapp[0].azurerm_private_dns_zone.anf_dns[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "Private DNS zone must be created for CZR failover hostname resolution",
		},
		"dnsARecordExists": {
			Expected:          "nil",
			ResourceMapName:   "module.netapp[0].azurerm_private_dns_a_record.anf_primary[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "DNS A record must be created for CZR failover hostname resolution",
		},
		"replicaVolumeZone": {
			Expected:          "2",
			ResourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf_replica[0]",
			AttributeJsonPath: "{$.zone}",
			Message:           "Replica volume must be in replication zone 2",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
