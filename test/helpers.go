package test

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"test/validation"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	tfjson "github.com/hashicorp/terraform-json"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"k8s.io/client-go/util/jsonpath"
)

type attrTuple struct {
	expectedValue string
	jsonPath      string
}

// getJsonPathFromResourcePlannedValuesMap retrieves the value of a jsonpath query on a given *terraform.PlanStruct
func getJsonPathFromResourcePlannedValuesMap(t *testing.T, plan *terraform.PlanStruct, resourceMapName string, jsonPath string) (string, error) {
	valuesMap, exists := plan.ResourcePlannedValuesMap[resourceMapName]
	if !exists {
		return "nil", nil
	}
	return getJsonPathFromStateResource(t, valuesMap, jsonPath)
}

// getJsonPathFromResourcePlannedValuesMap retrieves the value of a jsonpath query on a given *tfjson.StateResource
// map is visited in random order
func getJsonPathFromStateResource(t *testing.T, resource *tfjson.StateResource, jsonPath string) (string, error) {
	j := jsonpath.New("PlanParser")
	j.AllowMissingKeys(true)
	err := j.Parse(jsonPath)
	if err != nil {
		return "", err
	}
	buf := new(bytes.Buffer)
	err = j.Execute(buf, resource.AttributeValues)
	if err != nil {
		return "", err
	}
	out := buf.String()
	return out, nil
}

// getVariablesFromPlan retrieves the value from 'Variables' using variablesMapName and jsonPath
func getVariablesFromPlan(t *testing.T, plan *terraform.PlanStruct, resourceMapName string, jsonPath string) (string, error) {
	//valuesMap, exists := plan.RawPlan.Variables[resourceMapName]
	variablesMap := plan.RawPlan.Variables
	variables := variablesMap[resourceMapName]
	require.NotNil(t, variables)
	return getJsonPathFromPlannedVariablesMap(t, variables, jsonPath)
}

// getJsonPathFromResourcePlannedVariablesMap retrieves the value of a jsonpath query on a given *tfjson.StateResource
// map is visited in random order
func getJsonPathFromPlannedVariablesMap(t *testing.T, resourceMap *tfjson.PlanVariable, jsonPath string) (string, error) {
	j := jsonpath.New("PlanParser")
	j.AllowMissingKeys(true)
	err := j.Parse(jsonPath)
	if err != nil {
		return "", err
	}
	buf := new(bytes.Buffer)
	err = j.Execute(buf, resourceMap)
	if err != nil {
		return "", err
	}
	out := buf.String()
	return out, nil
}

func getOutputsFromPlan(t *testing.T, plan *terraform.PlanStruct, outputName string, jsonPath string) (string, error) {
	output, exists := plan.RawPlan.Variables[outputName]
	if !exists {
		return "nil", nil
	}
	require.NotNil(t, output)
	value := fmt.Sprintf("%v", output.Value)
	return value, nil
}

// getDefaultPlanVars returns a map of default terratest variables
func getDefaultPlanVars(t *testing.T) map[string]interface{} {
	tfVarsPath := "../examples/sample-input-defaults.tfvars"
	return getPlanVars(t, tfVarsPath)
}

// getPlanVars returns a map of terratest variables
func getPlanVars(t *testing.T, tfVarsPath string) map[string]interface{} {
	// Initialize the variables map
	variables := make(map[string]interface{})
	// Load variables from the tfvars file
	err := terraform.GetAllVariablesFromVarFileE(t, tfVarsPath, &variables)
	assert.NoError(t, err)

	// Add required variables for the test
	uniquePrefix := strings.ToLower(random.UniqueId())

	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus"
	variables["default_public_access_cidrs"] = []string{"123.45.67.89/16"}

	return variables
}

// initPlanWithVariables returns a *terraform.PlanStruct
func initPlanWithVariables(t *testing.T, variables map[string]interface{}) (*terraform.PlanStruct, error) {
	// Create a temporary plan file
	planFileName := "testplan-" + variables["prefix"].(string) + ".tfplan"
	planFilePath := filepath.Join(os.TempDir(), planFileName)
	defer os.Remove(planFilePath)

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "")
	// Get the path to the parent folder for clean up
	tempTestFolderSlice := strings.Split(tempTestFolder, string(os.PathSeparator))
	tempTestFolderPath := strings.Join(tempTestFolderSlice[:len(tempTestFolderSlice)-1], string(os.PathSeparator))
	defer os.RemoveAll(tempTestFolderPath)

	// Set up Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         variables,
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	return terraform.InitAndPlanAndShowWithStructE(t, terraformOptions)
}

// testCase struct defines the attributes for a test case
type testCase struct {
	expected          interface{}
	retriever         Retriever
	resourceMapName   string
	attributeJsonPath string
	assertFunction    assert.ComparisonAssertionFunc
	message           string
}

// runTest runs a test case
func runTest(t *testing.T, tc testCase, plan *terraform.PlanStruct) {
	retrieverFn := tc.retriever
	if retrieverFn == nil {
		retrieverFn = getJsonPathFromResourcePlannedValuesMap
	}
	actual, err := retrieverFn(t, plan, tc.resourceMapName, tc.attributeJsonPath)
	require.NoError(t, err)
	assertFn := tc.assertFunction
	if assertFn == nil {
		assertFn = assert.Equal
	}
	validateFn := validation.AssertComparison(assertFn, tc.expected)
	validateFn(t, actual, tc.message)
}

// A Retriever retrieves the value from a *terraform.PlanStruct plan,
// given a resource map name and json path
type Retriever func(t *testing.T, plan *terraform.PlanStruct, resourceMapName string, jsonPath string) (string, error)
