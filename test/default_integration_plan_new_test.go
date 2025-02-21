package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"test/validation"
)

type testParams struct {
	Expected          interface{}
	Retriever         Retriever
	ResourceMapName   string
	AttributeJsonPath string
	AssertFunction    assert.ComparisonAssertionFunc
}

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	defaultTests := map[string]testParams{
		"vnetTest": {Expected: "[\"192.168.0.0/16\"]", Retriever: resourceMapAttributeRetriever,
			ResourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
			AttributeJsonPath: "{$.address_space}",
			AssertFunction:    assert.Equal},
		"nodeVmAdminTest": {Expected: "azureuser", Retriever: stateResourceRetriever,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.linux_profile[0].admin_username}",
			AssertFunction:    assert.Equal},
	}

	variables := getDefaultPlanVars(t)
	uniquePrefix := strings.ToLower(random.UniqueId())
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	variables["default_public_access_cidrs"] = []string{"123.45.67.89/16"}
	plan, err := initPlanWithVariables(t, variables)
	assert.NoError(t, err)

	for name, tc := range defaultTests {
		t.Run(name, func(t *testing.T) {
			var validateFn validation.Validation
			validateFn = validation.AssertComparison(tc.AssertFunction, tc.Expected)
			retrieverFn := tc.Retriever
			actual := retrieverFn(plan, tc.ResourceMapName, tc.AttributeJsonPath)
			validateFn(t, actual)
		})
	}
}

// A Retriever is a function that retrieves a value from a plan.
type Retriever func(*terraform.PlanStruct, string, string) interface{}

// *****************************************
// Retriever Functions
// *****************************************

func resourceMapAttributeRetriever(plan *terraform.PlanStruct, resourceMapName string,
	attributeJsonPath string) interface{} {
	attribValue, _ := getJsonPathFromResourcePlannedValuesMap(plan, resourceMapName, attributeJsonPath)

	return attribValue
}

func stateResourceRetriever(plan *terraform.PlanStruct, resourceMapName string,
	attributeJsonPath string) interface{} {
	cluster := plan.ResourcePlannedValuesMap[resourceMapName]
	actualNodeVmAdmin, _ := getJsonPathFromStateResource(cluster, attributeJsonPath)
	return actualNodeVmAdmin
}
