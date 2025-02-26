/*
 * Copyright (c) 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
 */

package test

import (
	"fmt"
	"strconv"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestPlanACRDisabled(t *testing.T) {
	t.Parallel()

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = false
	variables["container_registry_admin_enabled"] = true
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	tests := map[string]TestCase{
		"ACRDoesNotExist": ACRDoesNotExist(),
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			tc.RunTest(t, plan)
		})
	}
}

func TestPlanACRStandard(t *testing.T) {
	t.Parallel()

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Standard"
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	tests := map[string]TestCase{
		"ACRExists":                    ACRExists(),
		"ACRNameContains":              ACRNameContains("acr"),
		"ACRSkuMatches":                ACRSkuMatches("Standard"),
		"ACRAdminMatches":              ACRAdminMatches(true),
		"ACRGeoReplicationsDoNotExist": ACRGeoReplicationsDoNotExist(),
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			tc.RunTest(t, plan)
		})
	}
}

func TestPlanACRPremium(t *testing.T) {
	t.Parallel()

	defaultGeoLocs := []string{"southeastus5", "southeastus3"}

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Premium"
	variables["container_registry_geo_replica_locs"] = defaultGeoLocs
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	tests := map[string]TestCase{
		"ACRExists":                         ACRExists(),
		"ACRNameContains":                   ACRNameContains("acr"),
		"ACRSkuMatches":                     ACRSkuMatches("Premium"),
		"ACRAdminMatches":                   ACRAdminMatches(true),
		"ACRGeoReplicationLocationsMatches": ACRGeoReplicationLocationsMatches(defaultGeoLocs),
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			tc.RunTest(t, plan)
		})
	}
}

func ACRDoesNotExist() TestCase {
	return &StateResourceDoesNotExistTestCase{
		path:    []string{"azurerm_container_registry.acr[0]"},
		message: "Azure Container Registry (ACR) present when it should not be",
	}
}

func ACRExists() TestCase {
	return &StateResourceExistsTestCase{
		path:    []string{"azurerm_container_registry.acr[0]"},
		message: "Azure Container Registry (ACR) not found in the Terraform plan",
	}
}

func ACRNameContains(name string) TestCase {
	return &StringContainsTestCase{
		expected: name,
		path:     []string{"azurerm_container_registry.acr[0]", "{$.name}"},
		message:  fmt.Sprintf("ACR name does not contain %s", name),
	}
}

func ACRSkuMatches(sku string) TestCase {
	return &StringCompareTestCase{
		expected: sku,
		path:     []string{"azurerm_container_registry.acr[0]", "{$.sku}"},
		message:  "Unexpected ACR SKU value",
	}
}

func ACRAdminMatches(enabled bool) TestCase {
	return &StringCompareTestCase{
		expected: strconv.FormatBool(enabled),
		path:     []string{"azurerm_container_registry.acr[0]", "{$.admin_enabled}"},
		message:  "Unexpected ACR admin_enabled value",
	}
}

func ACRGeoReplicationsDoNotExist() TestCase {
	return &StringCompareTestCase{
		expected: "[]",
		path:     []string{"azurerm_container_registry.acr[0]", "{$.georeplications}"},
		message:  "Geo-replications found when they should not be present",
	}
}

func ACRGeoReplicationLocationsMatches(expected []string) TestCase {
	return &ElementsMatchTestCase{
		expected: expected,
		path:     []string{"azurerm_container_registry.acr[0]", "{$.georeplications[*].location}"},
		message:  "Geo-replications do not match expected values",
	}
}
