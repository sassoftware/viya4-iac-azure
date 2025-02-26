package test

import (
	"strings"
	"testing"

	tfjson "github.com/hashicorp/terraform-json"
	"github.com/stretchr/testify/assert"
)

const ACR_STATEFUL_SOURCE = "azurerm_container_registry.acr[0]"

func TestPlanACRDisabled(t *testing.T) {
	t.Parallel()

	// Initialize the default variables map
	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = false
	variables["container_registry_admin_enabled"] = true
	plan, err := initPlanWithVariables(t, variables)
	assert.NoError(t, err)

	_, acrExists := plan.ResourcePlannedValuesMap[ACR_STATEFUL_SOURCE]
	assert.False(t, acrExists, "Azure Container Registry (ACR) present when it should not be")
}

func TestPlanACRStandard(t *testing.T) {
	t.Parallel()

	// Initialize the default variables map
	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Standard"
	plan, err := initPlanWithVariables(t, variables)
	assert.NoError(t, err)

	acrResource := plan.ResourcePlannedValuesMap[ACR_STATEFUL_SOURCE]
	commonAssertions(t, variables, acrResource)

	geoReplications, err := getJsonPathFromStateResource(t, acrResource, "{$.georeplications}")
	assert.NoError(t, err)
	assert.Equal(t, "[]", geoReplications, "Geo-replications found when they should not be present")
}

func TestPlanACRPremium(t *testing.T) {
	t.Parallel()

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Premium"
	variables["container_registry_geo_replica_locs"] = []string{"southeastus5", "southeastus3"}
	plan, err := initPlanWithVariables(t, variables)
	assert.NoError(t, err)

	acrResource := plan.ResourcePlannedValuesMap[ACR_STATEFUL_SOURCE]
	commonAssertions(t, variables, acrResource)

	// Validate geo-replication locations
	actualGeoReplications, err := getJsonPathFromStateResource(t, acrResource, "{$.georeplications[*].location}")
	assert.NoError(t, err)
	expectedGeoReplications := variables["container_registry_geo_replica_locs"].([]string)
	assert.ElementsMatch(t, expectedGeoReplications, strings.Fields(actualGeoReplications), "Geo-replications do not match expected values")
}

func commonAssertions(t *testing.T, variables map[string]interface{}, acrResource *tfjson.StateResource) {
	assert.True(t, acrResource != nil, "Azure Container Registry (ACR) not found in the Terraform plan")

	acrName, nameExists := acrResource.AttributeValues["name"].(string)
	assert.True(t, nameExists, "ACR name not found or is not a string")
	assert.Contains(t, acrName, "acr", "ACR name does not contain 'acr'")

	acrSKU, skuExists := acrResource.AttributeValues["sku"].(string)
	assert.True(t, skuExists, "ACR SKU not found or is not a string")
	expectedSKU, ok := variables["container_registry_sku"].(string)
	assert.True(t, ok, "'container_registry_sku' not found or is not a string")
	assert.Equal(t, expectedSKU, acrSKU, "Unexpected ACR SKU value")

	adminEnabled, adminExists := acrResource.AttributeValues["admin_enabled"].(bool)
	assert.True(t, adminExists, "ACR admin_enabled not found or is not a boolean")
	expectedAdminEnabled, ok := variables["container_registry_admin_enabled"].(bool)
	assert.True(t, ok, "'container_registry_admin_enabled' not found or is not a boolean")
	assert.Equal(t, expectedAdminEnabled, adminEnabled, "Unexpected ACR admin_enabled value")
}
