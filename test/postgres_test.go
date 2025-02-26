package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestPostgresServers verifies all PostgreSQL Flexible Server configurations
func TestPostgresServers(t *testing.T) {
	t.Parallel()

	variables := getDefaultPlanVars(t)
	variables["postgres_servers"] = map[string]interface{}{
		"default": map[string]interface{}{},
	}
	plan, err := initPlanWithVariables(t, variables)
	assert.NoError(t, err)

	// Validate PostgreSQL servers in Terraform plan
	postgresDefault := plan.ResourcePlannedValuesMap["module.flex_postgresql[\"default\"].azurerm_postgresql_flexible_server.flexpsql"]
	assert.NotNil(t, postgresDefault, "Default PostgreSQL Flexible Server should be created")

	// Validate SKU Name
	expectedSku := "GP_Standard_D4s_v3"
	assert.Equal(t, expectedSku, postgresDefault.AttributeValues["sku_name"], "Mismatch in SKU Name")

	//  Validate Storage Size (MB)
	expectedStorage := 131072
	actualStorage := int(postgresDefault.AttributeValues["storage_mb"].(float64))
	assert.Equal(t, expectedStorage, actualStorage, "Mismatch in Storage Size")

	//  Validate Backup Retention Days
	expectedBackupDays := 7
	actualBackupDays := int(postgresDefault.AttributeValues["backup_retention_days"].(float64))
	assert.Equal(t, expectedBackupDays, actualBackupDays, "Mismatch in Backup Retention Days")

	// Validate Geo-Redundant Backup
	expectedGeoRedundantBackup := false
	assert.Equal(t, expectedGeoRedundantBackup, postgresDefault.AttributeValues["geo_redundant_backup_enabled"], "Mismatch in Geo-Redundant Backup")

	//  Validate Administrator Login
	expectedAdminLogin := "pgadmin"
	assert.Equal(t, expectedAdminLogin, postgresDefault.AttributeValues["administrator_login"], "Mismatch in Administrator Login")

	//  Validate Administrator Password
	expectedAdminPassword := "my$up3rS3cretPassw0rd"
	assert.Equal(t, expectedAdminPassword, postgresDefault.AttributeValues["administrator_password"], "Mismatch in Administrator Password")

	//  Validate Server Version
	expectedServerVersion := "15"
	assert.Equal(t, expectedServerVersion, postgresDefault.AttributeValues["version"], "Mismatch in PostgreSQL Server Version")

	// Validate SSL Enforcement
	expectedSSLEnforcement := false
	requireSecureTransport, err := getJsonPathFromStateResource(t, postgresDefault, "{$.postgresql_configurations[*].require_secure_transport}")
	assert.NoError(t, err)
	sslEnforcementDisabled := requireSecureTransport == "OFF"
	assert.Equal(t, expectedSSLEnforcement, sslEnforcementDisabled, "Mismatch in SSL Enforcement: Expected False")

	//validate connectivity_method
	vnetAttr, vnetExists := postgresDefault.AttributeValues["virtual_network_id"]

	//The expected connectivity method
	expectedConnectivity := "public"

	// Infer connectivity type: if VNet is set, it's private; otherwise, it's public
	actualConnectivity := "public"
	if vnetExists && vnetAttr != nil {
		actualConnectivity = "private"
	}
	// Validate the inferred connectivity method
	assert.Equal(t, expectedConnectivity, actualConnectivity, "Mismatch in inferred Connectivity Method")

	//validate postgresql_configurations
	postgresConfig := plan.ResourcePlannedValuesMap["module.flex_postgresql[\"default\"].azurerm_postgresql_flexible_server_configuration.flexpsql[\"max_prepared_transactions\"]"]
	assert.NotNil(t, postgresConfig, "PostgreSQL Configuration for max_prepared_transactions should exist")

	// Validate name attribute
	expectedConfigName := "max_prepared_transactions"
	actualConfigName := postgresConfig.AttributeValues["name"].(string)
	assert.Equal(t, expectedConfigName, actualConfigName, "Mismatch in PostgreSQL Configuration Name")

	// Validate value attribute
	expectedConfigValue := "1024"
	actualConfigValue := postgresConfig.AttributeValues["value"].(string)
	assert.Equal(t, expectedConfigValue, actualConfigValue, "Mismatch in max_prepared_transactions configuration value")
}
