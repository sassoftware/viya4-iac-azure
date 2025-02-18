//go:build integration_plan_unit_tests

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

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestNodePools(t *testing.T) {
	plan := initializeNodePoolTestingPlan(t, true)

	testcases := map[string]testcase{
		// Simple
		"TestNodePoolNoError": {
			svFn: testNodePoolNoError,
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

	//runtimeCommonArgs := getCommonArgs(t)

	for name, tc := range testcases {
		t.Run(name, func(t *testing.T) {
			sv, err := tc.svFn(plan)
			require.NoError(t, err)
			sv.Execute(t)
		})
	}
}

func testNodePoolNoError(plan *terraform.PlanStruct) (*validation.SystemValidations, error) {
	sv := validation.SystemValidations{}
	sv.ExecutionError = validation.ErrorValidations{
		validation.ErrorRequire(require.NoError),
	}
	sv.Plan = plan

	return &sv, nil
}

func testNodePoolWithExpectedError(planStruct *terraform.PlanStruct) (*validation.SystemValidations, error) {
	sv := validation.SystemValidations{}

	sv.Stderr = validation.Validations{
		validation.AssertComparison(assert.Contains, `Deployment component 'foo' not found`),
	}
	return &sv, nil
}

func testNodePoolWithExpectedErrorAndStderrMsg(planStruct *terraform.PlanStruct) (*validation.SystemValidations, error) {
	sv := validation.SystemValidations{}

	sv.ExecutionError = validation.ErrorValidations{
		validation.ErrorRequire(require.Error),
	}
	sv.Stderr = validation.Validations{
		//validation.AssertComparison(assert.Contains, `Expected error message`),
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

func initializeNodePoolTestingPlan(t *testing.T, setVariable bool) *terraform.PlanStruct {
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
