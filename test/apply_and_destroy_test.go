package test

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

var resourceGroupName = ""
var clientID = ""
var clientSecret = ""
var tenantID = ""
var subscriptionID = "" // subscriptionID is overridden by the environment variable "ARM_SUBSCRIPTION_ID"

func TestMinimalInputIntegrationApply(t *testing.T) {
	t.Parallel()

	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-minimal.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	//  add the required variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	variables["default_public_access_cidrs"] = os.Getenv("TF_VAR_public_cidrs")

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "")
	// Get the path to the parent folder for clean up
	tempTestFolderSlice := strings.Split(tempTestFolder, string(os.PathSeparator))
	tempTestFolderPath := strings.Join(tempTestFolderSlice[:len(tempTestFolderSlice)-1], string(os.PathSeparator))
	defer os.RemoveAll(tempTestFolderPath)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         variables,
	}

	// Grab the client ID, client secret, and tenant ID from the environment
	clientID = os.Getenv("TF_VAR_client_id")
	clientSecret = os.Getenv("TF_VAR_client_secret")
	tenantID = os.Getenv("TF_VAR_tenant_id")

	// If the client ID, client secret, tenant ID, or public cidrs are not set, we should fail the test.
	if clientID == "" || clientSecret == "" || tenantID == "" || variables["default_public_access_cidrs"] == "" {
		t.Fatal("Environment variables TF_VAR_client_id, TF_VAR_client_secret, TF_VAR_tenant_id and TF_VAR_public_cidrs must be set")
	}

	// Log in to Azure CLI
	cmd := exec.Command("az", "login", "--service-principal",
		"--username", clientID,
		"--password", clientSecret,
		"--tenant", tenantID,
		"--output", "none")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		t.Fatalf("Error: %s\n", err)
	}

	t.Log("Successfully logged in to Azure CLI")

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanUpResources(t, terraformOptions)

	// This will run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	// Tests if the resource group exists
	resourceGroupName = fmt.Sprintf("terratest-%s-rg", uniquePrefix)
	exists, err := azure.ResourceGroupExistsE(resourceGroupName, subscriptionID)
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}
	assert.True(t, exists, "Resource group does not exist")

}

func cleanUpResources(t *testing.T, terraformOptions *terraform.Options) {
	// Destroy the resources
	_, err := terraform.DestroyE(t, terraformOptions)
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}

	// Check if the resource group still exists after destroy
	_, err = azure.ResourceGroupExistsE(resourceGroupName, subscriptionID)
	if err != nil {
		if strings.Contains(err.Error(), "ResourceGroupNotFound") {
			return
		}
		t.Errorf("Error: %s\n", err)
	}

	// If the resource group still exists, attempt to delete it via Azure CLI
	t.Log("Resource group still exists after destroy. Attempting to delete resource group via Azure CLI")
	del := exec.Command("az", "group", "delete",
		"--name", resourceGroupName,
		"--yes")
	del.Stdout = os.Stdout
	del.Stderr = os.Stderr

	if err := del.Run(); err != nil {
		//t.Fatalf("Error: %s\n", err)
		t.Errorf("Error: %s\n", err)
	}

}
