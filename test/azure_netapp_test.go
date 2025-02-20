package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestAzureNetApp(t *testing.T) {
	t.Parallel()

	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-defaults.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	//  add the required variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	// for Azure NetApp Files, we set storage_type = "ha"
	variables["storage_type"] = "ha"
	// Using a dummy CIDR for testing purposes
	variables["default_public_access_cidrs"] = []string{"123.45.67.89/16"}

	// Create a temporary file in the default temp directory
	planFileName := "testplan-" + uniquePrefix + ".tfplan"
	planFilePath := filepath.Join(os.TempDir(), planFileName)
	_, err := os.Create(planFilePath)
	require.NoError(t, err)
	defer os.Remove(planFilePath) // Ensure file is removed on exit

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located.
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options.
		Vars: variables,

		// Configure a plan file path so we can introspect the plan and make assertions about it.
		PlanFilePath: planFilePath,

		// Remove color codes to clean up output
		NoColor: true,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	// module.netapp[0].azurerm_netapp_account.anf should be created
	netAppAccountResource := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_account.anf"]
	assert.NotNil(t, netAppAccountResource, "module.netapp[0].azurerm_netapp_account.anf should exist")

	netappServiceLevelDefault := "Premium"
	var netappSizeInTBDefault float64 = 4
	netappProtocolsDefault := []interface{}{"NFSv4.1"}
	netappVolumePathDefault := "terratest-" + uniquePrefix + "-export"
	netappNetworkFeaturesDefault := "Basic"

	// module.netapp[0].azurerm_netapp_pool.anf should be created
	netAppPoolResource := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_pool.anf"]
	assert.NotNil(t, netAppPoolResource, "module.netapp[0].azurerm_netapp_pool.anf should exist")

	// netapp_service_level
	netAppPoolServiceLevel := netAppPoolResource.AttributeValues["service_level"]
	assert.Equal(t, netappServiceLevelDefault, netAppPoolServiceLevel, "Unexpected service level default value")

	// netapp_size_in_tb
	netAppPoolSize := netAppPoolResource.AttributeValues["size_in_tb"]
	assert.Equal(t, netappSizeInTBDefault, netAppPoolSize, "Unexpected size in tb default value")

	// module.netapp[0].azurerm_netapp_volume.anf should be created
	netAppVolumeResource := plan.ResourcePlannedValuesMap["module.netapp[0].azurerm_netapp_volume.anf"]
	assert.NotNil(t, netAppVolumeResource, "module.netapp[0].azurerm_netapp_volume.anf should exist")

	// netapp_protocols
	netAppVolumeProtocols := netAppVolumeResource.AttributeValues["protocols"]
	assert.Equal(t, netappProtocolsDefault, netAppVolumeProtocols, "Unexpected protocols default value")

	// netapp_service_level
	netAppVolumeServiceLevel := netAppVolumeResource.AttributeValues["service_level"]
	assert.Equal(t, netappServiceLevelDefault, netAppVolumeServiceLevel, "Unexpected service level default value")

	// netapp_volume_path
	netAppVolumePath := netAppVolumeResource.AttributeValues["volume_path"]
	assert.Equal(t, netappVolumePathDefault, netAppVolumePath, "Unexpected volume path default value")

	// netapp_network_features
	netAppVolumeNetworkFeatures := netAppVolumeResource.AttributeValues["network_features"]
	assert.Equal(t, netappNetworkFeaturesDefault, netAppVolumeNetworkFeatures, "Unexpected network features default value")

	// module.vnet.azurerm_subnet.subnet["netapp"] should be created
	netAppSubnetResource := plan.ResourcePlannedValuesMap["module.vnet.azurerm_subnet.subnet[\"netapp\"]"]
	assert.NotNil(t, netAppSubnetResource, "module.vnet.azurerm_subnet.subnet[\"netapp\"] should exist")

}
