// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPlanPostgresServers(t *testing.T) {
	t.Parallel()

	defaultPostgresServerName := "default"
	postgresResourceMapName := "module.flex_postgresql[\"" + defaultPostgresServerName + "\"].azurerm_postgresql_flexible_server.flexpsql"
	postgresFlexResourceMapName := "module.flex_postgresql[\"" + defaultPostgresServerName + "\"].azurerm_postgresql_flexible_server_configuration.flexpsql[\"max_prepared_transactions\"]"

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "postgres-servers"
	variables["postgres_servers"] = map[string]any{
		defaultPostgresServerName: map[string]any{},
	}

	tests := map[string]helpers.TestCase{
		"postgresFlexServerExists": {
			Expected:          `nil`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"postgresFlexServerSKUName": {
			Expected:          `GP_Standard_D4s_v3`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.sku_name}",
		},
		"postgresFlexServerStorageSize": {
			Expected:          `131072`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.storage_mb}",
		},
		"postgresFlexServerBackupRetentionDays": {
			Expected:          `7`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.backup_retention_days}",
		},
		"postgresFlexServerGeoRedundantBackup": {
			Expected:          `false`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.geo_redundant_backup_enabled}",
		},
		"postgresFlexServerAdminLogin": {
			Expected:          `pgadmin`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.administrator_login}",
		},
		"postgresFlexServerAdminPassword": {
			Expected:          `my$up3rS3cretPassw0rd`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.administrator_password}",
		},
		"postgresFlexServerVersion": {
			Expected:          `16`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.version}",
		},
		"postgresFlexServerSSLEnforcement": {
			Expected:          `OFF`,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.postgresql_configurations[*].require_secure_transport}",
			AssertFunction:    assert.NotEqual,
		},
		"postgresFlexServerVnetId": {
			Expected:          ``,
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.virtual_network_id}",
		},
		"postgresFlexServerConfigurationMaxPreparedTransactionsName": {
			Expected:          `max_prepared_transactions`,
			ResourceMapName:   postgresFlexResourceMapName,
			AttributeJsonPath: "{$.name}",
		},
		"postgresFlexServerConfigurationMaxPreparedTransactionsValue": {
			Expected:          `1024`,
			ResourceMapName:   postgresFlexResourceMapName,
			AttributeJsonPath: "{$.value}",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test PostgreSQL Zone-Redundant HA configuration.
func TestPlanPostgresHA(t *testing.T) {
	t.Parallel()

	postgresResourceMapName := `module.flex_postgresql["default"].azurerm_postgresql_flexible_server.flexpsql`

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "postgres-ha"
	variables["postgres_servers"] = map[string]any{
		"default": map[string]any{
			"high_availability_mode":    "ZoneRedundant",
			"availability_zone":         "1",
			"standby_availability_zone": "2",
		},
	}

	tests := map[string]helpers.TestCase{
		"haMode": {
			Expected:          "ZoneRedundant",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.high_availability[0].mode}",
			Message:           "high_availability mode must be ZoneRedundant",
		},
		"standbyAvailabilityZone": {
			Expected:          "2",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.high_availability[0].standby_availability_zone}",
			Message:           "standby_availability_zone must be 2",
		},
		"primaryAvailabilityZone": {
			Expected:          "1",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.zone}",
			Message:           "primary availability_zone must be 1",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test PostgreSQL private connectivity: private DNS zone and VNet link must be created,
// and public network access must be disabled.
// A postgresql subnet must be provided because it is not part of the default subnet config.
func TestPlanPostgresPrivate(t *testing.T) {
	t.Parallel()

	postgresResourceMapName := `module.flex_postgresql["default"].azurerm_postgresql_flexible_server.flexpsql`
	privateDnsZoneMapName := `module.flex_postgresql["default"].azurerm_private_dns_zone.flexpsql[0]`
	vnetLinkMapName := `module.flex_postgresql["default"].azurerm_private_dns_zone_virtual_network_link.flexpsql[0]`

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "postgres-private"
	variables["postgres_servers"] = map[string]any{
		"default": map[string]any{
			"connectivity_method": "private",
		},
	}
	// Add a postgresql subnet with the required delegation; not present in the default subnets map.
	variables["subnets"] = map[string]interface{}{
		"aks": map[string]interface{}{
			"prefixes":                                      []string{"192.168.0.0/23"},
			"service_endpoints":                             []string{"Microsoft.Sql"},
			"private_endpoint_network_policies":             "Enabled",
			"private_link_service_network_policies_enabled": false,
			"service_delegations":                           map[string]interface{}{},
		},
		"misc": map[string]interface{}{
			"prefixes":                                      []string{"192.168.2.0/24"},
			"service_endpoints":                             []string{"Microsoft.Sql"},
			"private_endpoint_network_policies":             "Enabled",
			"private_link_service_network_policies_enabled": false,
			"service_delegations":                           map[string]interface{}{},
		},
		"netapp": map[string]interface{}{
			"prefixes":                                      []string{"192.168.3.0/24"},
			"service_endpoints":                             []string{},
			"private_endpoint_network_policies":             "Disabled",
			"private_link_service_network_policies_enabled": false,
			"service_delegations": map[string]interface{}{
				"netapp": map[string]interface{}{
					"name":    "Microsoft.Netapp/volumes",
					"actions": []string{"Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"},
				},
			},
		},
		"postgresql": map[string]interface{}{
			"prefixes":                                      []string{"192.168.4.0/24"},
			"service_endpoints":                             []string{},
			"private_endpoint_network_policies":             "Disabled",
			"private_link_service_network_policies_enabled": false,
			"service_delegations": map[string]interface{}{
				"postgresql": map[string]interface{}{
					"name":    "Microsoft.DBforPostgreSQL/flexibleServers",
					"actions": []string{"Microsoft.Network/virtualNetworks/subnets/join/action"},
				},
			},
		},
	}

	tests := map[string]helpers.TestCase{
		"privateDnsZoneExists": {
			Expected:          "nil",
			ResourceMapName:   privateDnsZoneMapName,
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "Private DNS zone must be created for private PostgreSQL connectivity",
		},
		"vnetLinkExists": {
			Expected:          "nil",
			ResourceMapName:   vnetLinkMapName,
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "VNet link to private DNS zone must be created for private PostgreSQL connectivity",
		},
		"publicNetworkAccessDisabled": {
			Expected:          "false",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.public_network_access_enabled}",
			Message:           "public_network_access_enabled must be false for private connectivity",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
