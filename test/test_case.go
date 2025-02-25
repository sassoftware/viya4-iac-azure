/*
 * Copyright (c) 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
 */

package test

import (
	"errors"
	"strconv"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type TestCase interface {
	RunTest(t *testing.T, plan *terraform.PlanStruct)
}

// StringCompareTestCase tests that a string value in the plan matches what is expected.
type StringCompareTestCase struct {
	expected string
	path     []string
	message  string
}

func (testCase *StringCompareTestCase) RunTest(t *testing.T, plan *terraform.PlanStruct) {
	actual, err := getExpectedFromPlan(plan, testCase.path, "string")
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
	actual, err := getExpectedFromPlan(plan, testCase.path, "string")
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
	actual, err := getExpectedFromPlan(plan, testCase.path, "string_array")
	require.NoError(t, err)
	assert.ElementsMatch(t, actual, testCase.expected, testCase.message)
}

func getExpectedFromPlan(plan *terraform.PlanStruct, path []string, expectedType string) (any, error) {
	valuesMap := plan.ResourcePlannedValuesMap[path[0]]

	if expectedType == "string" {
		return getJsonPathFromStateResource(valuesMap, path[1])
	}
	if expectedType == "bool" {
		expected, err := getJsonPathFromStateResource(valuesMap, path[1])
		if err != nil {
			return nil, err
		}
		return strconv.ParseBool(expected)
	}
	if expectedType == "string_array" {
		expected, err := getJsonPathFromStateResource(valuesMap, path[1])
		if err != nil {
			return nil, err
		}
		return strings.Fields(expected), nil
	}
	return nil, errors.New("unknown return type")
}
