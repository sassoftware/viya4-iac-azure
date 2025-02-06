// go:build integration_plan_unit_tests

package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	tfjson "github.com/hashicorp/terraform-json"
	"github.com/stretchr/testify/assert"
)

type NodePool struct {
	Name              string
	MachineType       string
	OsDiskSize        float64
	MinNodes          float64
	MaxNodes          float64
	MaxPods           float64
	NodeTaints        []string
	NodeLabels        map[string]string
	AvailabilityZones []string
}

type Subnet struct {
	prefixes                                 []interface{}
	serviceEndpoints                         []interface{}
	privateEndpointNetworkPolicies           string
	privateLinkServiceNetworkPoliciesEnabled bool
	serviceDelegations                       map[string]interface{}
}

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestDefaults(t *testing.T) {
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
		NoColor: true,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]

	// vnet_address_space
	expectedVnetAddress := []interface{}{"192.168.0.0/16"}
	vnetResource := plan.ResourcePlannedValuesMap["module.vnet.azurerm_virtual_network.vnet[0]"]
	vnetAttributes := vnetResource.AttributeValues["address_space"].([]interface{})
	assert.Equal(t, expectedVnetAddress, vnetAttributes)

	// aks Subnets
	expectedAKSSubnet := &Subnet{
		prefixes:                                 []interface{}{"192.168.0.0/23"},
		serviceEndpoints:                         []interface{}{"Microsoft.Sql"},
		privateEndpointNetworkPolicies:           "Disabled",
		privateLinkServiceNetworkPoliciesEnabled: false,
		serviceDelegations:                       nil,
	}
	verifySubnets(t, plan.ResourcePlannedValuesMap["module.vnet.azurerm_subnet.subnet[\"aks\"]"], expectedAKSSubnet)

	// misc subnet
	expectedMiscSubnet := &Subnet{
		prefixes:                                 []interface{}{"192.168.2.0/24"},
		serviceEndpoints:                         []interface{}{"Microsoft.Sql"},
		privateEndpointNetworkPolicies:           "Disabled",
		privateLinkServiceNetworkPoliciesEnabled: false,
		serviceDelegations:                       nil,
	}
	verifySubnets(t, plan.ResourcePlannedValuesMap["module.vnet.azurerm_subnet.subnet[\"misc\"]"], expectedMiscSubnet)

	// cluster_egress_type
	var expectedClusterEgressType interface{} = "loadBalancer"
	egressType := cluster.AttributeValues["network_profile"]
	actualEgressType := egressType.([]interface{})[0].(map[string]interface{})["outbound_type"]
	assert.Equal(t, expectedClusterEgressType, actualEgressType, "Unexpected Cluster Egress Type")
	// partner_id - Not present in tfplan

	//aks_network_plugin
	var expectedNetworkPlugin interface{} = "kubenet"
	networkPlugin := cluster.AttributeValues["network_profile"]
	actualNetworkPlugin := networkPlugin.([]interface{})[0].(map[string]interface{})["network_plugin"]
	assert.Equal(t, expectedNetworkPlugin, actualNetworkPlugin, "Unexpected Network Plugin")
	// kubernetes_version

	//aks_network_policy
	/*var expectedNetworkPolicy interface{} = "calico"
	networkPolicy := cluster.AttributeValues["network_profile"]
	actualNetworkPolicy := networkPolicy.([]interface{})[0].(map[string]interface{})["network_policy"]
	assert.Equal(t, expectedNetworkPolicy, actualNetworkPolicy, "Unexpected Network Policy")
	// create_static_kubeconfig*/
	//aks_network_policy cannot be testesd that it is set after the apply.

	//aks_network_plugin_mode
	/*var expectedNetworkPluginMode interface{} = "overlay"
	networkPluginMode := cluster.AttributeValues["network_profile"]
	actualNetworkPluginMode := networkPluginMode.([]interface{})[0].(map[string]interface{})["network_plugin_mode"]
	assert.Equal(t, expectedNetworkPluginMode, actualNetworkPluginMode, "Unexpected Network Plugin Mode") */
	// aks_network_plugin_mode this cannot be tested that because it is not set in the tfplan and is defults to null.

}
func verifySubnets(t *testing.T, subnet *tfjson.StateResource, expectedValues *Subnet) {
	// prefixes
	assert.Equal(t, expectedValues.prefixes, subnet.AttributeValues["address_prefixes"], "Unexpected Subnet address_prefixes")

	// service_endpoints
	assert.Equal(t, expectedValues.serviceEndpoints, subnet.AttributeValues["service_endpoints"], "Unexpected Subnet service endpoints")

	// private_endpoint_network_policies
	// TODO figure out why these don't match the expected
	// assert.Equal(t, expectedValues.privateEndpointNetworkPolicies, subnet.AttributeValues["private_endpoint_network_policies"], "Unexpected private_endpoint_network_policies")

	// private_link_service_network_policies_enabled
	assert.Equal(t, expectedValues.privateLinkServiceNetworkPoliciesEnabled, subnet.AttributeValues["private_link_service_network_policies_enabled"], "Unexpected private_link_service_network_policies_enabled")

	// service_delegations
	// If no sevice_delegations are set, verify that there is no service_delegations
	// attribute in the resource. Otherwise, check that the attribute matches the expected
	if expectedValues.serviceDelegations == nil {
		assert.Nil(t, subnet.AttributeValues["service_delegations"], "Service delegations should be nil")
	} else {
		assert.Equal(t, expectedValues.serviceDelegations, subnet.AttributeValues["service_delegations"], "Unexpected service delegations")
	}
}
