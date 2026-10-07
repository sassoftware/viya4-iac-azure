// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPlanACRStandard(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "acr-standard"
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Standard"

	tests := map[string]helpers.TestCase{
		"acrGeoRepsNotExistTest": {
			Expected:          "[]",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.georeplications}",
			Message:           "Geo-replications found when they should not be present",
		},
		"nameTest": {
			Expected:          "acr",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.name}",
			AssertFunction:    assert.Contains,
			Message:           "ACR name does not contain 'acr'",
		},
		"skuTest": {
			Expected:          "Standard",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.sku}",
			Message:           "Unexpected ACR SKU value",
		},
		"adminEnabledTest": {
			Expected:          "true",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.admin_enabled}",
			Message:           "Unexpected ACR admin_enabled value",
		},
	}

	plan := helpers.GetPlanFromCache(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Verify ACR premium
func TestPlanACRPremium(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "acr-premium"
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Premium"
	variables["container_registry_geo_replica_locs"] = []string{"southeastus5", "southeastus3"}

	tests := map[string]helpers.TestCase{
		"locationsTest": {
			Expected:          "southeastus3 southeastus5",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.georeplications[*].location}",
			Message:           "Geo-replications do not match expected values",
		},
		"nameTest": {
			Expected:          "acr",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.name}",
			AssertFunction:    assert.Contains,
			Message:           "ACR name does not contain 'acr'",
		},
		"skuTest": {
			Expected:          "Premium",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.sku}",
			Message:           "Unexpected ACR SKU value",
		},
		"adminEnabledTest": {
			Expected:          "true",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.admin_enabled}",
			Message:           "Unexpected ACR admin_enabled value",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test ACR with admin access disabled (the recommended production default).
func TestPlanACRAdminDisabled(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "acr-admin-disabled"
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = false
	variables["container_registry_sku"] = "Standard"

	tests := map[string]helpers.TestCase{
		"adminDisabledTest": {
			Expected:          "false",
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$.admin_enabled}",
			Message:           "ACR admin_enabled must be false when container_registry_admin_enabled=false",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
