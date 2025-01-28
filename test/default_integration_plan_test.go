//go:build integration_plan_tests

package test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestGeneral(t *testing.T) {
	t.Parallel()

	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-defaults.tfvars"

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

	// Add this logging for NetApp resources as JSON
	for _, resource := range plan.ResourceChangesMap {
		if strings.Contains(resource.Address, "azurerm_netapp") {
			jsonBytes, err := json.MarshalIndent(resource, "", "  ")
			if err != nil {
				t.Errorf("Failed to marshal resource to JSON: %v", err)
				continue
			}
			t.Logf("\nNetApp Resource JSON:\n%s\n", string(jsonBytes))
		}
	}

	// Get resources from plan
	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]
	// pool := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_pool.anf"]
	// volume := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_volume.anf"]

	// partner_id - Not present in tfplan

	//create_static_kubeconfig - Not present in tfplan

	// kubernetes_version
	k8sVersion := cluster.AttributeValues["kubernetes_version"]
	assert.Equal(t, k8sVersion, "1.30", "Unexpected Kubernetes version")

	// create_jump_vm
	// Verify that the jump vm has been created
	jumpVM := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_linux_virtual_machine.vm"]
	assert.NotNil(t, jumpVM, "Jump VM should be created")

	// create_jump_public_ip
	jumpPublicIP := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_public_ip.vm_ip[0]"]
	assert.NotNil(t, jumpPublicIP, "Jump VM public IP should exist")

	// enable_jump_public_static_ip
	assert.Equal(t, jumpPublicIP.AttributeValues["allocation_method"], "Static", "Jump VM should use static IP")

	// jump_vm_admin
	assert.Equal(t, jumpVM.AttributeValues["admin_username"], "jumpuser", "Unexpected jump VM admin username")

	// jump_vm_machine_type
	assert.Equal(t, jumpVM.AttributeValues["size"], "Standard_B2s", "Unexpected jump VM machine type")

	// jump_rwx_filestore_path - in the output but not the tfplan?

	// tags - defaults to empty so there is nothing to test. If we wanted to test it, this is how we would
	// aksTags := cluster.AttributeValues["tags"]
	// assert.Equal(t, aksTags, map[string]interface{}(map[string]interface{}{"test": "test"}), "Unexpected AKS Tags")

	// aks_identity
	userAssignedIdentity := plan.ResourcePlannedValuesMap["azurerm_user_assigned_identity.uai[0]"]
	assert.NotNil(t, userAssignedIdentity, "The User Identity should exist.")

	// ssh_public_key
	// TODO figure this out
	assert.NotNil(t, cluster.AttributeValues["linux_profile[0]"], "SSH Key should exist")

	// cluster_api_mode

	// aks_cluster_private_dns_zone_id

	// aks_cluster_sku_tier

	// cluster_support_tier

}
