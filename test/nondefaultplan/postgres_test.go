// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
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
			Expected:          `15`,
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
