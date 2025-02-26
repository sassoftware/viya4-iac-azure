/*
 * Copyright (c) 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
 */

package test

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
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

	tests := map[string]ACRTestCase{
		"ACRDoesNotExist": &StateResourceDoesNotExistTestCase{
			path:    []string{"azurerm_container_registry.acr[0]"},
			message: "Azure Container Registry (ACR) present when it should not be",
		},
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

	tests := defaultACRTests(variables)
	tests["ACRGeoReplicationsDoNotExist"] = &StringCompareTestCase{
		expected: "[]",
		path:     []string{"azurerm_container_registry.acr[0]", "{$.georeplications}"},
		message:  "Geo-replications found when they should not be present",
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

	tests := defaultACRTests(variables)
	tests["ACRGeoReplicationLocationsMatches"] = &ElementsMatchTestCase{
		expected: defaultGeoLocs,
		path:     []string{"azurerm_container_registry.acr[0]", "{$.georeplications[*].location}"},
		message:  "Geo-replications do not match expected values",
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			tc.RunTest(t, plan)
		})
	}
}

func defaultACRTests(variables map[string]interface{}) map[string]ACRTestCase {
	name := "acr"
	sku := variables["container_registry_sku"].(string)
	adminEnabled := variables["container_registry_admin_enabled"].(bool)

	return map[string]ACRTestCase{
		"ACRExists": &StateResourceExistsTestCase{
			path:    []string{"azurerm_container_registry.acr[0]"},
			message: "Azure Container Registry (ACR) not found in the Terraform plan",
		},
		"ACRNameContains": &StringContainsTestCase{
			expected: name,
			path:     []string{"azurerm_container_registry.acr[0]", "{$.name}"},
			message:  fmt.Sprintf("ACR name does not contain %s", name),
		},
		"ACRSkuMatches": &StringCompareTestCase{
			expected: sku,
			path:     []string{"azurerm_container_registry.acr[0]", "{$.sku}"},
			message:  "Unexpected ACR SKU value",
		},
		"ACRAdminMatches": &StringCompareTestCase{
			expected: strconv.FormatBool(adminEnabled),
			path:     []string{"azurerm_container_registry.acr[0]", "{$.admin_enabled}"},
			message:  "Unexpected ACR admin_enabled value",
		},
	}
}

const (
	STRING = iota
	STRING_ARRAY
)

// ACRTestCase this is an experimental design for testing.  Keeping this tucked in the acr test for now
// with the option to adopt it later.
type ACRTestCase interface {
	RunTest(t *testing.T, plan *terraform.PlanStruct)
}

// StringCompareTestCase tests that a string value in the plan matches what is expected.
type StringCompareTestCase struct {
	expected string
	path     []string
	message  string
}

func (testCase *StringCompareTestCase) RunTest(t *testing.T, plan *terraform.PlanStruct) {
	actual, err := getExpectedFromPlan(plan, testCase.path, STRING)
	require.NoError(t, err)
	assert.Equal(t, testCase.expected, actual, testCase.message)
}

// StringContainsTestCase tests that a string value in the plan contains the expected sub string.
type StringContainsTestCase struct {
	expected string
	path     []string
	message  string
}

func (testCase *StringContainsTestCase) RunTest(t *testing.T, plan *terraform.PlanStruct) {
	actual, err := getExpectedFromPlan(plan, testCase.path, STRING)
	require.NoError(t, err)
	assert.Contains(t, actual, testCase.expected, testCase.message)
}

// StateResourceExistsTestCase tests that a state resource exists at the specified path.
type StateResourceExistsTestCase struct {
	path    []string
	message string
}

func (testCase *StateResourceExistsTestCase) RunTest(t *testing.T, plan *terraform.PlanStruct) {
	_, exists := plan.ResourcePlannedValuesMap[testCase.path[0]]
	assert.True(t, exists, testCase.message)
}

// StateResourceDoesNotExistTestCase tests that a state resources does not exist at the specified path.
type StateResourceDoesNotExistTestCase struct {
	path    []string
	message string
}

func (testCase *StateResourceDoesNotExistTestCase) RunTest(t *testing.T, plan *terraform.PlanStruct) {
	_, exists := plan.ResourcePlannedValuesMap[testCase.path[0]]
	assert.False(t, exists, testCase.message)
}

// ElementsMatchTestCase tests that the elements between two arrays match.
type ElementsMatchTestCase struct {
	expected []string
	path     []string
	message  string
}

func (testCase *ElementsMatchTestCase) RunTest(t *testing.T, plan *terraform.PlanStruct) {
	actual, err := getExpectedFromPlan(plan, testCase.path, STRING_ARRAY)
	require.NoError(t, err)
	assert.ElementsMatch(t, actual, testCase.expected, testCase.message)
}

// Note: implement changes here if the path array changes
func getExpectedFromPlan(plan *terraform.PlanStruct, path []string, expectedType int) (any, error) {
	valuesMap := plan.ResourcePlannedValuesMap[path[0]]

	switch expectedType {
	case STRING:
		return getJsonPathFromStateResource(valuesMap, path[1])
	case STRING_ARRAY:
		expected, err := getJsonPathFromStateResource(valuesMap, path[1])
		if err != nil {
			return nil, err
		}
		return strings.Fields(expected), nil
	default:
		return nil, errors.New("unknown return type")
	}
}
