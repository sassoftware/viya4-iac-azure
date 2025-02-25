package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// TestAdminAccess verifies that NSG rules for admin access are correctly applied in the Terraform plan.
func TestAdminAccess(t *testing.T) {
	t.Parallel()

	// Generate a unique prefix for test isolation
	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-defaults.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	// Add required test variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	// Using a dummy CIDR for testing purposes
	variables["default_public_access_cidrs"] = []interface{}{"123.45.67.89/16"}

	// Create a temporary Terraform plan file
	planFileName := "testplan-" + uniquePrefix + ".tfplan"
	planFilePath := filepath.Join("/tmp/", planFileName)
	defer os.Remove(planFilePath) // Cleanup after test execution

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "")
	defer os.RemoveAll(tempTestFolder)

	// Configure Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         variables,
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	actualDefaultCidr, hasDefaultCidr := plan.RawPlan.Variables["default_public_access_cidrs"]
	actualClusterCidr, hasClusterCidr := plan.RawPlan.Variables["cluster_endpoint_public_access_cidrs"]
	actualVmCidr, hasVmCidr := plan.RawPlan.Variables["vm_public_access_cidrs"]
	actualPostgresCidr, hasPostgresCidr := plan.RawPlan.Variables["postgres_public_access_cidrs"]
	actualAcrCidr, hasAcrCidr := plan.RawPlan.Variables["acr_public_access_cidrs"]

	//  Validate Default Public Access CIDRs
	expectedDefaultCidr := variables["default_public_access_cidrs"]
	assert.True(t, hasDefaultCidr, "default_public_access_cidrs should exist in plan")
	assert.Equal(t, expectedDefaultCidr, actualDefaultCidr.Value, "Mismatch in default_public_access_cidrs")

	// Validate Cluster Endpoint Public Access CIDRs
	expectedClusterCidr := variables["cluster_endpoint_public_access_cidrs"]
	assert.True(t, hasClusterCidr, "cluster_endpoint_public_access_cidrs should exist in plan")
	assert.Equal(t, expectedClusterCidr, actualClusterCidr.Value, "Mismatch in cluster_endpoint_public_access_cidrs")

	// Validate VM Public Access CIDRs
	expectedVmCidr := variables["vm_public_access_cidrs"]
	assert.True(t, hasVmCidr, "vm_public_access_cidrs should exist in plan")
	assert.Equal(t, expectedVmCidr, actualVmCidr.Value, "Mismatch in vm_public_access_cidrs")

	// Validate PostgreSQL Public Access CIDRs
	expectedPostgresCidr := variables["postgres_public_access_cidrs"]
	assert.True(t, hasPostgresCidr, "postgres_public_access_cidrs should exist in plan")
	assert.Equal(t, expectedPostgresCidr, actualPostgresCidr.Value, "Mismatch in postgres_public_access_cidrs")

	// Validate ACR Public Access CIDRs
	expectedAcrCidr := variables["acr_public_access_cidrs"]
	assert.True(t, hasAcrCidr, "acr_public_access_cidrs should exist in plan")
	assert.Equal(t, expectedAcrCidr, actualAcrCidr.Value, "Mismatch in acr_public_access_cidrs")
}
