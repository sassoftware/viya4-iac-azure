// go:build integration_plan_unit_tests

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

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestNodeVMAdmin(t *testing.T) {
	t.Parallel()

	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "examples/sample-input-defaults.tfvars"

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

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located.
		TerraformDir: ".",

		// Variables to pass to our Terraform code using -var options.
		Vars: variables,

		// Configure a plan file path so we can introspect the plan and make assertions about it.
		PlanFilePath: planFilePath,

		// Remove color codes to clean up output
		NoColor: false,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]

	// node_vm_admin
	expectedNodeVMAdmin := "azureuser"
	nodeVMAdmin := cluster.AttributeValues["linux_profile"]
	actualNodeVMAdmin := nodeVMAdmin.([]interface{})[0].(map[string]interface{})["admin_username"]
	assert.Equal(t, expectedNodeVMAdmin, actualNodeVMAdmin, "Unexpected Node VM Admin User")

	//default_nodepool_vm_type
	expectedNodepoolVMType := "Standard_E8s_v5"
	nodePool := cluster.AttributeValues["default_node_pool"]
	actualNodepoolVMType := nodePool.([]interface{})[0].(map[string]interface{})["vm_size"]
	assert.Equal(t, expectedNodepoolVMType, actualNodepoolVMType, "Unexpected Default Node Pool VM Type")

	//default_nodepool_os_disk_size
	expectedNodepoolOSDiskSize := float64(128)
	actualNodepoolOSDiskSize := nodePool.([]interface{})[0].(map[string]interface{})["os_disk_size_gb"]
	assert.Equal(t, expectedNodepoolOSDiskSize, actualNodepoolOSDiskSize, "Unexpected Default Node Pool OS Disk Size")

	//default_nodepool_max_pods
	expectedNodepoolMaxPods := float64(110)
	actualNodepoolMaxPods := nodePool.([]interface{})[0].(map[string]interface{})["max_pods"]
	assert.Equal(t, expectedNodepoolMaxPods, actualNodepoolMaxPods, "Unexpected Default Node Pool Max Pods")

	//default_nodepool_min_nodes
	expectedNodepoolMinNodes := float64(1)
	actualNodepoolMinNodes := nodePool.([]interface{})[0].(map[string]interface{})["min_count"]
	assert.Equal(t, expectedNodepoolMinNodes, actualNodepoolMinNodes, "Unexpected Default Node Pool Min Nodes")

	//default_nodepool_max_nodes
	expectedNodepoolMaxNodes := float64(5)
	actualNodepoolMaxNodes := nodePool.([]interface{})[0].(map[string]interface{})["max_count"]
	assert.Equal(t, expectedNodepoolMaxNodes, actualNodepoolMaxNodes, "Unexpected Default Node Pool Max Nodes")

	//default_nodepool_availability_zones
	expectedNodepoolAvailability := []interface{}{"1"}
	actualNodepoolAvailability := nodePool.([]interface{})[0].(map[string]interface{})["zones"]
	assert.Equal(t, expectedNodepoolAvailability, actualNodepoolAvailability, "Unexpected Default Node Pool Zones")

}
