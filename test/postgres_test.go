package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	DefaultPostgresServerName = "default"
)

// TestPostgresServers verifies all PostgreSQL Flexible Server configurations
func TestPostgresServers(t *testing.T) {
	t.Parallel()

	postgresResourceMapName := "module.flex_postgresql[\"" + DefaultPostgresServerName + "\"].azurerm_postgresql_flexible_server.flexpsql"
	tests := map[string]testCase{
		"postgresFlexServerExists": {
			expected:          `nil`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"postgresFlexServerSKUName": {
			expected:          `GP_Standard_D4s_v3`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.sku_name}",
		},
		"postgresFlexServerStorageSize": {
			expected:          `131072`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.storage_mb}",
		},
		"postgresFlexServerBackupRetentionDays": {
			expected:          `7`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.backup_retention_days}",
		},
		"postgresFlexServerGeoRedundantBackup": {
			expected:          `false`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.geo_redundant_backup_enabled}",
		},
		"postgresFlexServerAdminLogin": {
			expected:          `pgadmin`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.administrator_login}",
		},
		"postgresFlexServerAdminPassword": {
			expected:          `my$up3rS3cretPassw0rd`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.administrator_password}",
		},
		"postgresFlexServerVersion": {
			expected:          `15`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.version}",
		},
		"postgresFlexServerSSLEnforcement": {
			expected:          `OFF`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.postgresql_configurations[*].require_secure_transport}",
			assertFunction:    assert.NotEqual,
		},
		"postgresFlexServerVnetId": {
			expected:          ``,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.virtual_network_id}",
		},
		"postgresFlexServerConfigurationMaxPreparedTransactionsName": {
			expected:          `max_prepared_transactions`,
			resourceMapName:   "module.flex_postgresql[\"" + DefaultPostgresServerName + "\"].azurerm_postgresql_flexible_server_configuration.flexpsql[\"max_prepared_transactions\"]",
			attributeJsonPath: "{$.name}",
		},
		"postgresFlexServerConfigurationMaxPreparedTransactionsValue": {
			expected:          `1024`,
			resourceMapName:   "module.flex_postgresql[\"" + DefaultPostgresServerName + "\"].azurerm_postgresql_flexible_server_configuration.flexpsql[\"max_prepared_transactions\"]",
			attributeJsonPath: "{$.value}",
		},
	}

	// Prepare to generate the plan
	variables := getDefaultPlanVars(t)
	variables["postgres_servers"] = map[string]any{
		DefaultPostgresServerName: map[string]any{},
	}

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
