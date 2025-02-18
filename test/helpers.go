package test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/testing"
	"github.com/tidwall/gjson"
)

func getValueFromResourcePlannedValuesMap(plan *terraform.PlanStruct, resourceMapName string, resourcePath string) gjson.Result {
	valuesMap := plan.ResourcePlannedValuesMap[resourceMapName]
	values, _ := json.Marshal(valuesMap.AttributeValues)
	return gjson.Get(string(values), resourcePath)
}

func getDefaultPlanVars(t testing.TestingT) map[string]interface{} {
	// Generate a unique test prefix

	tfVarsPath := "../examples/sample-input-defaults.tfvars"

	// Initialize the variables map
	variables := make(map[string]interface{})

	// Load variables from the tfvars file
	err := terraform.GetAllVariablesFromVarFileE(t, tfVarsPath, &variables)
	if err != nil {
		t.Fatalf("Failed to load variables from tfvars file: %v", err)
	}

	// Add required variables for the test
	variables["location"] = "eastus"
	variables["default_public_access_cidrs"] = strings.Split(os.Getenv("TF_VAR_public_cidrs"), ",")

	return variables
}

func initPlanWithVariables(t testing.TestingT, variables map[string]interface{}) *terraform.PlanStruct {
	uniquePrefix := strings.ToLower(random.UniqueId())
	variables["prefix"] = "terratest-" + uniquePrefix

	// Create a temporary plan file
	planFileName := "acr-testplan-" + uniquePrefix + ".tfplan"
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
