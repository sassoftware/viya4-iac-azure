package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestPostgresServers verifies all PostgreSQL Flexible Server configurations
func TestPostgresServers(t *testing.T) {
	t.Parallel()

	// Generate a unique prefix for isolation
	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-defaults.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	// Add required test variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	variables["postgres_servers"] = map[string]interface{}{
		"default": map[string]interface{}{},
	}
	variables["default_public_access_cidrs"] = []string{"123.45.67.89/16"}

	// Create a temporary Terraform plan file
	planFileName := "testplan-" + uniquePrefix + ".tfplan"
	planFilePath := filepath.Join("/tmp/", planFileName)
	defer os.Remove(planFilePath) // Ensure cleanup after test execution

	// Configure Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars:         variables,
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

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
	const expectedSSLEnforcement = false

	sslEnforcementDisabled := false

	configurationsAttr, exists := postgresDefault.AttributeValues["postgresql_configurations"]

	var configurationsList []interface{}
	if exists && configurationsAttr != nil {
		configurationsList, _ = configurationsAttr.([]interface{})
		for _, config := range configurationsList {
			configMap, isMap := config.(map[string]interface{})
			if isMap {
				if name, ok := configMap["name"].(string); ok && name == "require_secure_transport" {
					if value, ok := configMap["value"].(string); ok && value == "OFF" {
						sslEnforcementDisabled = true
						break
					}
				}
			}
		}
	}

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
