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

type testcase struct {
	svFn func(planStruct *terraform.PlanStruct) (*validation.SystemValidations, error)
}

// *****************************************
// Registered Test Functions
// *****************************************

func VnetCompareFunc(t *testing.T, actual interface{}, messages ...interface{}) {
	// vnet_address_space
	expectedVnetAddress := []interface{}{"192.168.0.0/16"}
	plan := actual.(*terraform.PlanStruct)
	vnetResource := plan.ResourcePlannedValuesMap["module.vnet.azurerm_virtual_network.vnet[0]"]
	vnetAttributes := vnetResource.AttributeValues["address_space"].([]interface{})
	//t.Log(actualVnet, expectedVnet, messages)
	assert.Equal(t, expectedVnetAddress, vnetAttributes)
}

func NodeVmAdminCompareFunc(t *testing.T, actual interface{}, messages ...interface{}) {
	expectedNodeVMAdmin := "azureuser"
	plan := actual.(*terraform.PlanStruct)
	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]
	nodeVMAdmin := cluster.AttributeValues["linux_profile"]
	actualNodeVMAdmin := nodeVMAdmin.([]interface{})[0].(map[string]interface{})["admin_username"]
	//t.Log(actualNodeVMAdmin, expectedNodeVMAdmin, messages)
	assert.Equal(t, expectedNodeVMAdmin, actualNodeVMAdmin, "Unexpected Node VM Admin User")
}

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	plan := initializeDefaultTestingPlan(t, true)

	testcases := map[string]testcase{
		// Simple
		"TestPlanDefaults": {
			svFn: testPlanDefaults,
		},
		//// Errors
		//"TestNodePoolWithExpectedError": {
		//	svFn: testNodePoolWithExpectedError,
		//},
		//// Errors
		//"TestNodePoolWithExpectedErrorAndStderrMsg": {
		//	svFn: testNodePoolWithExpectedErrorAndStderrMsg,
		//},
	}

	for name, tc := range testcases {
		t.Run(name, func(t *testing.T) {
			// create a SystemValidation instance with actual values
			// and validation functions to be called by the 'sv.Execute()'
			sv, err := tc.svFn(plan)
			require.NoError(t, err)
			// run the registered validation functions
			sv.Execute(t)
		})
	}
}

// Create a SystemValidations instance for defaults testing.
// Add the validation functions to the SystemValidations
// to validate the many expected default values
func testPlanDefaults(plan *terraform.PlanStruct) (*validation.SystemValidations, error) {
	sv := validation.SystemValidations{}
	sv.ExecutionError = validation.ErrorValidations{
		validation.ErrorRequire(require.NoError),
	}
	sv.Plan = plan

	sv.PlanValidations = validation.Validations{
		VnetCompareFunc,
		NodeVmAdminCompareFunc,
	}
	return &sv, nil
}

func testNodePoolWithExpectedError(planStruct *terraform.PlanStruct) (*validation.SystemValidations, error) {
	sv := validation.SystemValidations{}
	return &sv, nil
}

func testNodePoolWithExpectedErrorAndStderrMsg(planStruct *terraform.PlanStruct) (*validation.SystemValidations, error) {
	sv := validation.SystemValidations{}

	sv.ExecutionError = validation.ErrorValidations{
		validation.ErrorRequire(require.Error),
	}
	return &sv, nil
}

// *****************************************
// Utililty Functions
// *****************************************

// Common arguments.
func getCommonArgs(t *testing.T) []string {
	return []string{}
}

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
