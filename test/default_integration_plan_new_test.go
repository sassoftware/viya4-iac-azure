package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"test/validation"
)

type TestParams struct {
	Expected       interface{}
	Retriever      Retriever
	AssertFunction assert.ComparisonAssertionFunc
}

// A Retriever is a function that retrieves a value from a plan.
type Retriever func(*terraform.PlanStruct) interface{}

var (
	tests = map[string]TestParams{
		"vnetTest":        {Expected: "192.168.0.0/16", Retriever: vnetRetriever, AssertFunction: assert.Equal},
		"nodeVmAdminTest": {Expected: "azureuser", Retriever: nodeVmAdminRetriever, AssertFunction: assert.Equal},
	}
)

// *****************************************
// Retriever Functions
// *****************************************

func vnetRetriever(plan *terraform.PlanStruct) interface{} {
	vnetResource := plan.ResourcePlannedValuesMap["module.vnet.azurerm_virtual_network.vnet[0]"]
	vnetAttributes := vnetResource.AttributeValues["address_space"].([]interface{})
	return vnetAttributes[0]
}

func nodeVmAdminRetriever(plan *terraform.PlanStruct) interface{} {
	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]
	nodeVMAdmin := cluster.AttributeValues["linux_profile"]
	actualNodeVmAdmin := nodeVMAdmin.([]interface{})[0].(map[string]interface{})["admin_username"]
	return actualNodeVmAdmin
}

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	plan := initializeDefaultTestingPlan(t, true)

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			validateFn := validation.AssertComparison(tc.AssertFunction, tc.Expected)
			retrieverFn := tc.Retriever
			actual := retrieverFn(plan)
			validateFn(t, actual)
		})
	}

}

// *****************************************
// Utililty Functions
// *****************************************

func initializeDefaultTestingPlan(t *testing.T, setVariable bool) *terraform.PlanStruct {
	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-defaults.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	//  add the required variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	// Using a dummy CIDR for testing purposes
	variables["default_public_access_cidrs"] = []string{"123.45.67.89/16"}

	// Create a temporary file in the default temp directory
	planFileName := "testplan-" + uniquePrefix + ".tfplan"
	planFilePath := filepath.Join(os.TempDir(), planFileName)
	_, err := os.Create(planFilePath)
	require.NoError(t, err)
	defer os.Remove(planFilePath) // Ensure file is removed on exit

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located.
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options.
		Vars: variables,

		// Configure a plan file path so we can introspect the plan and make assertions about it.
		PlanFilePath: planFilePath,

		// Remove color codes to clean up output
		NoColor: true,
	}
	return terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
}
