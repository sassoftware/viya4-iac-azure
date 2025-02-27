package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

// Verify Acr disabled stuff
// TestAdminAccess verifies that NSG rules for admin access are correctly applied in the Terraform plan.
func TestAdminAccessNew(t *testing.T) {
	adminAccessTests := map[string]testCase{
		"defaultCidrTest": {
			expected:        "[123.45.67.89/16]",
			resourceMapName: "default_public_access_cidrs",
			retriever:       getVariablesFromPlan,
			message:         "Mismatch in default_public_access_cidrs",
		},
		"clusterCidrTest": {
			expected:        "<nil>",
			resourceMapName: "cluster_endpoint_public_access_cidrs",
			retriever:       getVariablesFromPlan,
			message:         "Mismatch in cluster_endpoint_public_access_cidrs",
		},
		"vmCidrTest": {
			expected:        "<nil>",
			resourceMapName: "vm_public_access_cidrs",
			retriever:       getVariablesFromPlan,
			message:         "Mismatch in vm_public_access_cidrs",
		},
		"postgresCidrTest": {
			expected:        "<nil>",
			resourceMapName: "vm_public_access_cidrs",
			retriever:       getVariablesFromPlan,
			message:         "Mismatch in postgres_public_access_cidrs",
		},
		"acrCidrTest": {
			expected:        "<nil>",
			resourceMapName: "acr_public_access_cidrs",
			retriever:       getVariablesFromPlan,
			message:         "Mismatch in acr_public_access_cidrs",
		},
	}

	// Generate a unique prefix for test isolation
	uniquePrefix := strings.ToLower(random.UniqueId())
	variables := getDefaultPlanVars(t)
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	// Using a dummy CIDR for testing purposes
	variables["default_public_access_cidrs"] = []interface{}{"123.45.67.89/16"}
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range adminAccessTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Retriever function. Note the unused jsonPath parameter
func getVariablesFromPlan(t *testing.T, plan *terraform.PlanStruct, outputName string, jsonPath string) (string, error) {
	output, exists := plan.RawPlan.Variables[outputName]
	if !exists {
		return "nil", nil
	}
	require.NotNil(t, output)
	value := fmt.Sprintf("%v", output.Value)
	return value, nil
}
