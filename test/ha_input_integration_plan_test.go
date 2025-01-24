//go:build integration_plan_tests

package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestHAStorageIntegrationPlan(t *testing.T) {
	t.Parallel()

	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-ha.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	//  add the required variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	variables["default_public_access_cidrs"] = strings.Split(os.Getenv("TF_VAR_public_cidrs"), ",")

	// Create a temporary file in the default temp directory
	planFileName := "testplan-" + uniquePrefix + ".tfplan"
	planFilePath := filepath.Join("/tmp/", planFileName)
	defer os.Remove(planFilePath) // Ensure file is removed on exit
	os.Create(planFilePath)

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "")

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located.
		TerraformDir: tempTestFolder,

		// Variables to pass to our Terraform code using -var options.
		Vars: variables,

		// Configure a plan file path so we can introspect the plan and make assertions about it.
		PlanFilePath: planFilePath,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	pool := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_pool.anf"]
	volume := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_volume.anf"]

	pool_capacity := pool.AttributeValues["size_in_tb"]
	assert.Equal(t, pool_capacity, float64(4), "Did not receive expected Storage capacity")

	network_feature := volume.AttributeValues["network_features"]
	assert.Equal(t, network_feature, "Basic", "Did not receive expected network features capacity")
}
