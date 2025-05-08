// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"testing"
)

// TupleTestCase struct which encapsulates a range of tests against a single resource map.
type TupleTestCase struct {
	Expected map[string]AttrTuple
}

type AttrTuple struct {
	ExpectedValue string
	JsonPath      string
}

// TestCase struct defines the attributes for a test case
type TestCase struct {
	Expected          interface{}
	Retriever         Retriever
	ResourceMapName   string
	AttributeJsonPath string
	AssertFunction    assert.ComparisonAssertionFunc
	Message           string
}

// A Retriever retrieves the value from a *terraform.PlanStruct plan,
// given a resource map name and json path
type Retriever func(plan *terraform.PlanStruct, resourceMapName string, jsonPath string) (string, error)

// RetrieveFromRawPlan Retriever that gets a value from the raw plan variables
func RetrieveFromRawPlan(plan *terraform.PlanStruct, outputName string, jsonPath string) (string, error) {
	output, exists := plan.RawPlan.Variables[outputName]
	if !exists {
		return "nil", nil
	}
	value := fmt.Sprintf("%v", output.Value)
	return value, nil
}

// RetrieveFromResourcePlannedValuesMap Retriever that gets the value of a jsonpath query on a given *terraform.PlanStruct
func RetrieveFromResourcePlannedValuesMap(plan *terraform.PlanStruct, resourceMapName string, jsonPath string) (string, error) {
	valuesMap, exists := plan.ResourcePlannedValuesMap[resourceMapName]
	if !exists {
		return "nil", nil
	}
	return GetJsonPathFromStateResource(valuesMap, jsonPath)
}

// RetrieveFromRawPlanResource Retriever that gets the value from 'Variables' using variablesMapName and jsonPath
func RetrieveFromRawPlanResource(plan *terraform.PlanStruct, resourceMapName string, jsonPath string) (string, error) {
	variables, exists := plan.RawPlan.Variables[resourceMapName]
	if !exists {
		return "", nil
	}
	return GetJsonPathFromPlannedVariablesMap(variables, jsonPath)
}

// RetrieveFromPlan is used by the apply logic to retrieve a value to compare the deployed resources against
func RetrieveFromPlan(plan *terraform.PlanStruct, resourceMapName string, jsonPath string) func() string {
	return func() string {
		valuesMap, exists := plan.ResourcePlannedValuesMap[resourceMapName]
		if !exists {
			return "nil"
		}
		actual, err := GetJsonPathFromStateResource(valuesMap, jsonPath)
		if err != nil {
			return "nil"
		}
		return actual
	}
}

// RunTest runs a test case
func RunTest(t *testing.T, tc TestCase, plan *terraform.PlanStruct) {
	retrieverFn := tc.Retriever
	if retrieverFn == nil {
		retrieverFn = RetrieveFromResourcePlannedValuesMap
	}
	actual, err := retrieverFn(plan, tc.ResourceMapName, tc.AttributeJsonPath)
	require.NoError(t, err)
	assertFn := tc.AssertFunction
	if assertFn == nil {
		assertFn = assert.Equal
	}
	validateFn := AssertComparison(assertFn, tc.Expected)
	validateFn(t, actual, tc.Message)
}

// RunTests ranges over a set of test cases and runs them
func RunTests(t *testing.T, tests map[string]TestCase, plan *terraform.PlanStruct) {
	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			RunTest(t, tc, plan)
		})
	}
}

// RunTupleTests ranges over a set of tuple test cases and runs each subtest for the given resource map
func RunTupleTests(t *testing.T, resourceMapNameFmt string, tests map[string]TupleTestCase, plan *terraform.PlanStruct) {
	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			resourceMapName := fmt.Sprintf(resourceMapNameFmt, name)
			for attrName, attrTuple := range tc.Expected {
				t.Run(attrName, func(t *testing.T) {
					RunTest(t, TestCase{
						Expected:          attrTuple.ExpectedValue,
						ResourceMapName:   resourceMapName,
						AttributeJsonPath: attrTuple.JsonPath,
					}, plan)
				})
			}
		})
	}
}
