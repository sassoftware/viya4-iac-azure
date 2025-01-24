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
	pool := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_pool.anf"]
	volume := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_volume.anf"]

	// 1. Main Jump VM Resource
	jumpVM := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_linux_virtual_machine.vm"]
	assert.NotNil(t, jumpVM, "Jump VM should be created")
	assert.Equal(t, jumpVM.AttributeValues["admin_username"], "jumpuser", "Unexpected jump VM admin username")
	assert.Equal(t, jumpVM.AttributeValues["size"], "Standard_B2s", "Unexpected jump VM machine type")

	// 2. Public IP Resource
	jumpPublicIP := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_public_ip.vm_ip[0]"]
	assert.NotNil(t, jumpPublicIP, "Jump VM public IP should exist")
	assert.Equal(t, jumpPublicIP.AttributeValues["allocation_method"], "Static", "Jump VM should use static IP")

	// 3. Network Interface
	//jumpNIC := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_network_interface.nic"]
	//assert.NotNil(t, jumpNIC, "Jump VM network interface should exist")

	// 4. Network Security Group
	//jumpNSG := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_network_security_group.nsg"]
	//assert.NotNil(t, jumpNSG, "Jump VM network security group should exist")

	// 5. NSG Association
	//jumpNSGAssoc := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_network_interface_security_group_association.nsg_association"]
	//assert.NotNil(t, jumpNSGAssoc, "Jump VM NSG association should exist")

	// Save plan to JSON for debugging
	jsonBytes, err := json.MarshalIndent(plan, "", "  ")

	if err != nil {
		t.Errorf("Failed to marshal plan to JSON: %v", err)
	} else {

		outputPath := filepath.Join("test_output", "terraform_plan.json")
		os.MkdirAll(filepath.Dir(outputPath), 0755)
		if err := os.WriteFile(outputPath, jsonBytes, 0644); err != nil {
			t.Errorf("Failed to write JSON file: %v", err)
		} else {
			t.Logf("Full plan saved to: %s", outputPath)
		}
	}

	// partner_id
	// create_static_kubeconfig

	// kubernetes_version - AKS cluster Kubernetes version
	k8sVersion := cluster.AttributeValues["kubernetes_version"]
	assert.Equal(t, k8sVersion, "1.29", "Unexpected Kubernetes version")

	// create_jump_vm

	// create_jump_public_ip

	// enable_jump_public_static_ip

	// jump_vm_admin

	// jump_vm_machine_type

	// jump_rwx_filestore_path

	// tags

	// aks_identity - UserAssignedIdentity or Service Principal for AKS
	//identity := cluster.AttributeValues["identity"].([]interface{})[0].(map[string]interface{})
	//assert.Equal(t, identity["type"], "UserAssigned", "Unexpected AKS identity type")

	// ssh_public_key

	// cluster_api_mode - Public or private IP for cluster api
	apiServerAccess := cluster.AttributeValues["api_server_access_profile"].([]interface{})[0].(map[string]interface{})
	assert.Equal(t, apiServerAccess["enable_private_cluster"], false, "Unexpected cluster API mode")

	// aks_cluster_private_dns_zone_id - DNS zone resource ID for private cluster
	assert.Equal(t, apiServerAccess["private_dns_zone_id"], "", "Unexpected private DNS zone ID")

	// aks_cluster_sku_tier - SKU Tier for Kubernetes Cluster
	skuTier := cluster.AttributeValues["sku_tier"]
	assert.Equal(t, skuTier, "Free", "Unexpected AKS SKU tier")

	// cluster_support_tier

}
