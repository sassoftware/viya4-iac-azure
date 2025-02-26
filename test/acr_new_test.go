package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

//const ACR_STATEFUL_SOURCE = "azurerm_container_registry.acr[0]"

// Verify Acr disabled stuff
func TestPlanAcrDisabledNew(t *testing.T) {
	acrDisabledTests := map[string]testCase{
		"acrDisabledTest": {
			expected:          "",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$}",
			retriever:         resourceRetrieverRequireNotExist,
			message:           "Azure Container Registry (ACR) present when it should not be",
		},
	}

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = false
	variables["container_registry_admin_enabled"] = true
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range acrDisabledTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Verify Acr standard stuff
func TestPlanACRStandardNew(t *testing.T) {
	acrStandardTests := map[string]testCase{
		"acrGeoRepsNotExistTest": {
			expected:          "[]",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.georeplications}",
			message:           "Geo-replications found when they should not be present",
		},
		"nameTest": {
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.name}",
			assertFunction:    assert.Contains,
			message:           "ACR name does not contain 'acr'",
		},
		"skuTest": {
			expected:          "Standard",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.sku}",
			message:           "Unexpected ACR SKU value",
		},
		"adminEnabledTest": {
			expected:          "true",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.admin_enabled}",
			message:           "Unexpected ACR admin_enabled value",
		},
	}

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Standard"
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	resource, resourceExists := plan.ResourcePlannedValuesMap["azurerm_container_registry.acr[0]"]
	require.True(t, resourceExists)
	acrName, nameExists := resource.AttributeValues["name"].(string)
	require.True(t, nameExists)
	nameTestCase := acrStandardTests["nameTest"]
	nameTestCase.expected = acrName
	acrStandardTests["nameTest"] = nameTestCase

	for name, tc := range acrStandardTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Verify Acr premium stuff
func TestPlanACRPremiumNew(t *testing.T) {
	acrPremiumTests := map[string]testCase{
		"locationsTest": {
			expected:          "southeastus3 southeastus5",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.georeplications[*].location}",
			message:           "Geo-replications do not match expected values",
		},
		"nameTest": {
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.name}",
			assertFunction:    assert.Contains,
			message:           "ACR name does not contain 'acr'",
		},
		"skuTest": {
			expected:          "Premium",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.sku}",
			message:           "Unexpected ACR SKU value",
		},
		"adminEnabledTest": {
			expected:          "true",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.admin_enabled}",
			message:           "Unexpected ACR admin_enabled value",
		},
	}

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Premium"
	variables["container_registry_geo_replica_locs"] = []string{"southeastus5", "southeastus3"}
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	resource, resourceExists := plan.ResourcePlannedValuesMap["azurerm_container_registry.acr[0]"]
	require.True(t, resourceExists)
	acrName, nameExists := resource.AttributeValues["name"].(string)
	require.True(t, nameExists)
	nameTestCase := acrPremiumTests["nameTest"]
	nameTestCase.expected = acrName
	acrPremiumTests["nameTest"] = nameTestCase

	for name, tc := range acrPremiumTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func resourceRetrieverRequireNotExist(t *testing.T, plan *terraform.PlanStruct, resourceMapName string,
	attributeJsonPath string) (string, error) {
	_, exists := plan.ResourcePlannedValuesMap[resourceMapName]
	assert.False(t, exists, resourceMapName+"."+attributeJsonPath+" should not be present")
	return "", nil
}
