package defaultapply

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestApplyResourceGroupOld(t *testing.T) {
	t.Parallel()

	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../../examples/sample-input-defaults.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	//  add the required variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	variables["default_public_access_cidrs"] = os.Getenv("TF_VAR_public_cidrs")

	// Create a temporary plan file
	planFileName := "testplan-" + variables["prefix"].(string) + ".tfplan"
	planFilePath := filepath.Join(os.TempDir(), planFileName)
	defer os.Remove(planFilePath)

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../../", "")
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

	// Check if the required environment variables are set, fail the test run if not
	if os.Getenv("TF_VAR_client_id") == "" || os.Getenv("TF_VAR_client_secret") == "" || os.Getenv("TF_VAR_tenant_id") == "" || os.Getenv("TF_VAR_subscription_id") == "" || variables["default_public_access_cidrs"] == "" {
		t.Fatal("Environment variables TF_VAR_client_id, TF_VAR_client_secret, TF_VAR_tenant_id, TF_VAR_subscription_id, and TF_VAR_public_cidrs must be set")
	}

	// This will run `terraform init` and `terraform plan`
	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	// Grab resource attributes from the plan for azurerm_resource_group.aks_rg[0]
	resourceGroupID := plan.ResourcePlannedValuesMap["azurerm_resource_group.aks_rg[0]"].AttributeValues["id"] //known after apply
	assert.Nil(t, resourceGroupID, "Resource group ID known after apply")
	resourceGroupLocation := plan.ResourcePlannedValuesMap["azurerm_resource_group.aks_rg[0]"].AttributeValues["location"]
	resourceGroupName := plan.ResourcePlannedValuesMap["azurerm_resource_group.aks_rg[0]"].AttributeValues["name"]

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer DestroyDouble(t, terraformOptions)

	// This will run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	// Tests if the resource group exists
	exists, err := azure.ResourceGroupExistsE(resourceGroupName.(string), os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}
	assert.True(t, exists, "Resource group does not exist")
	// Get the resource group attributes and check if they are correct
	resourceGroup, err := azure.GetAResourceGroupE(resourceGroupName.(string), os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}
	assert.Equal(t, resourceGroupLocation, *resourceGroup.Location, "Resource group location is incorrect")
	assert.Equal(t, resourceGroupName, *resourceGroup.Name, "Resource group name is incorrect")
	assert.NotNil(t, *resourceGroup.ID, "Resource group ID is nil")

}

func DestroyDouble(t *testing.T, terraformOptions *terraform.Options) {
	//Destroy the resources we created
	_, err := terraform.DestroyE(t, terraformOptions)
	if err != nil {
		//If the first destroy fails, try to destroy again
		_, out := terraform.DestroyE(t, terraformOptions)
		// If the second destroy fails, fail the test for further investigation
		if out != nil {
			t.Errorf("Error: %s\n", out)
		}
	}

	return
}

// func cleanUpResources(t *testing.T, terraformOptions *terraform.Options) {
// 	// Destroy the resources
// 	_, err := terraform.DestroyE(t, terraformOptions)
// 	if err != nil {
// 		t.Errorf("Error: %s\n", err)
// 	}

// 	// Check if the resource group still exists after destroy
// 	_, err = azure.ResourceGroupExistsE(resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
// 	if err != nil {
// 		if strings.Contains(err.Error(), "ResourceGroupNotFound") {
// 			return
// 		}
// 		t.Errorf("Error: %s\n", err)
// 	}

// 	//Log in to Azure CLI
// 	cmd := exec.Command("az", "login", "--service-principal",
// 		"--username", clientID,
// 		"--password", clientSecret,
// 		"--tenant", tenantID,
// 		"--output", "none")
// 	cmd.Stdout = os.Stdout
// 	cmd.Stderr = os.Stderr

// 	if err := cmd.Run(); err != nil {
// 		t.Fatalf("Error: %s\n", err)
// 	}

// 	// If the resource group still exists, attempt to delete it via Azure CLI
// 	t.Log("Resource group still exists after destroy. Attempting to delete resource group via Azure CLI")
// 	del := exec.Command("az", "group", "delete",
// 		"--name", resourceGroupName,
// 		"--yes")
// 	del.Stdout = os.Stdout
// 	del.Stderr = os.Stderr

// 	if err := del.Run(); err != nil {
// 		t.Errorf("Error: %s\n", err)
// 	}

// }
