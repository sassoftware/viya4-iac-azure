package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestACRVariables(t *testing.T) {
	t.Parallel()

	// Generate a unique test prefix
	uniquePrefix := strings.ToLower(random.UniqueId())
	tfVarsPath := "examples/sample-input-defaults.tfvars" // Path to your tfvars file

	// Initialize the variables map
	variables := make(map[string]interface{})

	// Load variables from the tfvars file
	err := terraform.GetAllVariablesFromVarFileE(t, tfVarsPath, &variables)
	if err != nil {
		t.Fatalf("Failed to load variables from tfvars file: %v", err)
	}

	// Add required variables for the test
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus"

	// Print loaded variables for debugging
	fmt.Printf("Loaded variables: %+v\n", variables)

	// Create a temporary plan file
	planFileName := "acr-testplan-" + uniquePrefix + ".tfplan"
	planFilePath := filepath.Join("/tmp/", planFileName)
	defer os.Remove(planFilePath)

	// Set up Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: ".", // Replace with the actual directory of your Terraform configurations
		Vars:         variables,
		VarFiles:     []string{tfVarsPath},
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	// Run Terraform init and plan
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)

	// Show the Terraform plan
	plan := terraform.ShowWithStruct(t, terraformOptions)

	// Print plan for debugging
	fmt.Printf("Terraform plan: %+v\n", plan.ResourcePlannedValuesMap)

	// Validate the ACR resource only if 'create_container_registry' is true
	createACR, ok := variables["create_container_registry"].(bool)
	assert.True(t, ok, "'create_container_registry' not found or is not a boolean")

	if createACR {
		acrResource, acrExists := plan.ResourcePlannedValuesMap["azurerm_container_registry.acr[0]"]
		assert.True(t, acrExists, "Azure Container Registry (ACR) not found in the Terraform plan")

		if acrExists {
			// Check ACR name
			acrName, nameExists := acrResource.AttributeValues["name"].(string)
			assert.True(t, nameExists, "ACR name not found or is not a string")
			assert.Contains(t, acrName, "acr", "ACR name does not contain 'acr'")

			// Check the ACR SKU
			acrSKU, skuExists := acrResource.AttributeValues["sku"].(string)
			assert.True(t, skuExists, "ACR SKU not found or is not a string")
			expectedSKU, ok := variables["container_registry_sku"].(string)
			assert.True(t, ok, "'container_registry_sku' not found or is not a string")
			fmt.Printf("Expected SKU: %s, Actual SKU: %s\n", expectedSKU, acrSKU)
			assert.Equal(t, expectedSKU, acrSKU, "Unexpected ACR SKU value")

			// Check if admin is enabled
			adminEnabled, adminExists := acrResource.AttributeValues["admin_enabled"].(bool)
			assert.True(t, adminExists, "ACR admin_enabled not found or is not a boolean")
			expectedAdminEnabled, ok := variables["container_registry_admin_enabled"].(bool)
			assert.True(t, ok, "'container_registry_admin_enabled' not found or is not a boolean")
			assert.Equal(t, expectedAdminEnabled, adminEnabled, "Unexpected ACR admin_enabled value")

			// Check geo-replications for Premium SKU
			if acrSKU == "Premium" {
				geoReplications, geoExists := acrResource.AttributeValues["georeplications"].([]interface{})
				assert.True(t, geoExists, "Geo-replications not found for Premium SKU")
				assert.NotEmpty(t, geoReplications, "Geo-replications list should not be empty for Premium SKU")

				// Validate geo-replication locations
				expectedGeoReplications, ok := variables["container_registry_geo_replica_locs"].([]string)
				assert.True(t, ok, "'container_registry_geo_replica_locs' not found or is not a list of strings")
				var actualGeoReplications []string
				for _, geo := range geoReplications {
					geoMap := geo.(map[string]interface{})
					actualGeoReplications = append(actualGeoReplications, geoMap["location"].(string))
				}
				assert.ElementsMatch(t, expectedGeoReplications, actualGeoReplications, "Geo-replications do not match expected values")
			}
		}
	}
}
