//go:build integration_plan_unit_tests

package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	tfjson "github.com/hashicorp/terraform-json"
	"github.com/stretchr/testify/assert"
)

func TestPlanACRDisabled(t *testing.T) {
	t.Parallel()

	variables := initializeDefaultVariables(t)
	variables["create_container_registry"] = false
	plan := createTestPlan(t, variables)

	_, acrExists := plan.ResourcePlannedValuesMap["azurerm_container_registry.acr[0]"]
	assert.False(t, acrExists, "Azure Container Registry (ACR) present when it should not be")
}

func TestPlanACRStandard(t *testing.T) {
	t.Parallel()

	variables := initializeDefaultVariables(t)
	variables["container_registry_sku"] = "Standard"
	plan := createTestPlan(t, variables)

	acrResource := plan.ResourcePlannedValuesMap["azurerm_container_registry.acr[0]"]
	commonAssertions(t, variables, acrResource)

	geoReplications := acrResource.AttributeValues["georeplications"].([]interface{})
	assert.Empty(t, geoReplications, "Geo-replications found when they should not be present")
}

func TestPlanACRPremium(t *testing.T) {
	t.Parallel()

	variables := initializeDefaultVariables(t)
	variables["container_registry_sku"] = "Premium"
	variables["container_registry_geo_replica_locs"] = []string{"southeastus5", "southeastus3"}
	plan := createTestPlan(t, variables)

	acrResource := plan.ResourcePlannedValuesMap["azurerm_container_registry.acr[0]"]
	commonAssertions(t, variables, acrResource)

	// Validate geo-replication locations
	geoReplications := acrResource.AttributeValues["georeplications"].([]interface{})
	assert.NotEmpty(t, geoReplications, "Geo-replications should not be empty for Premium SKU")
	var actualGeoReplications []string
	for _, geo := range geoReplications {
		geoMap := geo.(map[string]interface{})
		actualGeoReplications = append(actualGeoReplications, geoMap["location"].(string))
	}
	expectedGeoReplications := variables["container_registry_geo_replica_locs"].([]string)
	assert.ElementsMatch(t, expectedGeoReplications, actualGeoReplications, "Geo-replications do not match expected values")
}

func initializeDefaultVariables(t *testing.T) map[string]interface{} {
	// Generate a unique test prefix
	uniquePrefix := strings.ToLower(random.UniqueId())
	tfVarsPath := "../examples/sample-input-defaults.tfvars"

	variables := make(map[string]interface{})

	// Load variables from the tfvars file
	err := terraform.GetAllVariablesFromVarFileE(t, tfVarsPath, &variables)
	if err != nil {
		t.Fatalf("Failed to load variables from tfvars file: %v", err)
	}

	// Add required variables for the test
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus"
	variables["default_public_access_cidrs"] = strings.Split(os.Getenv("TF_VAR_public_cidrs"), ",")
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	return variables
}

func createTestPlan(t *testing.T, variables map[string]interface{}) *terraform.PlanStruct {
	// Create a temporary plan file
	planFileName := "acr-plan-" + variables["prefix"].(string) + ".tfplan"
	planFilePath := filepath.Join("/tmp/", planFileName)
	defer os.Remove(planFilePath)

	// Set up Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars:         variables,
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	return terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
}

func commonAssertions(t *testing.T, variables map[string]interface{}, acrResource *tfjson.StateResource) {
	assert.True(t, acrResource != nil, "Azure Container Registry (ACR) not found in the Terraform plan")

	acrName, nameExists := acrResource.AttributeValues["name"].(string)
	assert.True(t, nameExists, "ACR name not found or is not a string")
	assert.Contains(t, acrName, "acr", "ACR name does not contain 'acr'")

	acrSKU, skuExists := acrResource.AttributeValues["sku"].(string)
	assert.True(t, skuExists, "ACR SKU not found or is not a string")
	expectedSKU, ok := variables["container_registry_sku"].(string)
	assert.True(t, ok, "'container_registry_sku' not found or is not a string")
	assert.Equal(t, expectedSKU, acrSKU, "Unexpected ACR SKU value")

	adminEnabled, adminExists := acrResource.AttributeValues["admin_enabled"].(bool)
	assert.True(t, adminExists, "ACR admin_enabled not found or is not a boolean")
	expectedAdminEnabled, ok := variables["container_registry_admin_enabled"].(bool)
	assert.True(t, ok, "'container_registry_admin_enabled' not found or is not a boolean")
	assert.Equal(t, expectedAdminEnabled, adminEnabled, "Unexpected ACR admin_enabled value")
}
