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

// TestNetworkingVariables validates VNet and Subnet configurations
func TestNetworkingVariables(t *testing.T) {
	t.Parallel()

	// Generate a unique test prefix
	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-defaults.tfvars" // Path to your tfvars file

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	// Add required variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"

	// Create a temporary plan file
	planFileName := "testplan-" + uniquePrefix + ".tfplan"
	planFilePath := filepath.Join("/tmp/", planFileName)
	defer os.Remove(planFilePath)
	os.Create(planFilePath)

	// Terraform options configuration
	terraformOptions := &terraform.Options{
		TerraformDir: "../", // Path to the Terraform code
		Vars:         variables,
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	// Run terraform init, plan, and capture the structured plan
	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	// Validate VNet and subnets
	validateVNetAndSubnets(t, plan)
}

func validateVNetAndSubnets(t *testing.T, plan *terraform.PlanStruct) {
	// Validate VNet
	vnetResource, ok := plan.ResourcePlannedValuesMap["module.vnet.azurerm_virtual_network.vnet[0]"]
	if !ok || vnetResource == nil {
		t.Fatalf("VNet resource not found in the Terraform plan")
	}

	vnetAddress := vnetResource.AttributeValues["address_space"].([]interface{})[0].(string)
	assert.Equal(t, "192.168.0.0/16", vnetAddress, "Unexpected VNet address space")

	// Validate AKS subnet
	aksSubnet, ok := plan.ResourcePlannedValuesMap["module.vnet.azurerm_subnet.subnet[\"aks\"]"]
	if !ok || aksSubnet == nil {
		t.Fatalf("AKS Subnet not found in the Terraform plan")
	}

	aksSubnetAddress := aksSubnet.AttributeValues["address_prefixes"].([]interface{})[0].(string)
	assert.Equal(t, "192.168.0.0/23", aksSubnetAddress, "Unexpected AKS subnet address prefix")

	// Validate Misc subnet
	miscSubnet, ok := plan.ResourcePlannedValuesMap["module.vnet.azurerm_subnet.subnet[\"misc\"]"]
	if !ok || miscSubnet == nil {
		t.Fatalf("Misc Subnet not found in the Terraform plan")
	}

	miscSubnetAddress := miscSubnet.AttributeValues["address_prefixes"].([]interface{})[0].(string)
	assert.Equal(t, "192.168.2.0/24", miscSubnetAddress, "Unexpected Misc subnet address prefix")
}
