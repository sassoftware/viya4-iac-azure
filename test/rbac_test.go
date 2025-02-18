//go:build integration_plan_unit_tests

package test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/tidwall/gjson"
)

func TestRbacVariables(t *testing.T) {
	t.Parallel()

	// Generate a unique test prefix
	uniquePrefix := strings.ToLower(random.UniqueId())
	tfVarsPath := "../examples/sample-input-defaults.tfvars"

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
	variables["default_public_access_cidrs"] = strings.Split(os.Getenv("TF_VAR_public_cidrs"), ",")

	// Set RBAC to true
	variables["rbac_aad_tenant_id"] = "2492e7f7-df5d-4f17-95dc-63528774e820"
	variables["rbac_aad_enabled"] = true

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

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]
	values, _ := json.Marshal(cluster.AttributeValues)
	ids := gjson.Get(string(values), "azure_active_directory_role_based_access_control.admin_group_object_ids")
	rbac_aad_tenant_id := gjson.Get(string(values), "azure_active_directory_role_based_access_control.rbac_aad_tenant_id")
	assert.Nil(t, ids.Value())
	assert.Nil(t, rbac_aad_tenant_id.Value())
}

//func gjson.Result getValueFromResourcePlannedValuesMap(map map, string value){
//	plannedValuesMap := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]
//	gjson.Get(string(values), "azure_active_directory_role_based_access_control.admin_group_object_ids")
//}
