// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

// Package validation ...
package validation

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// A Validation is a function that executes a validation check.
type Validation func(t *testing.T, actual interface{}, messages ...interface{})

// Validations houses a list of Validation.
type Validations []Validation

// Execute loops through each Validation and runs its Execute.
func (validations Validations) Execute(t *testing.T, actual interface{}, messages ...interface{}) {
	for _, validation := range validations {
		validation(t, actual, messages...)
	}
}

// AssertComparison creates a Validation using the given assert
// comparison assertion function.
func AssertComparison(fn assert.ComparisonAssertionFunc, expected interface{}) Validation {
	if invertArgs(fn) {
		return func(t *testing.T, actual interface{}, messages ...interface{}) {
			fn(t, actual, expected, messages...)
		}
	}
	return func(t *testing.T, actual interface{}, messages ...interface{}) {
		fn(t, expected, actual, messages...)
	}
}

// AssertValue creates a Validation using the given assert
// value assertion function.
func AssertValue(fn assert.ValueAssertionFunc) Validation {
	return func(t *testing.T, actual interface{}, messages ...interface{}) {
		fn(t, actual, messages...)
	}
}

// RequireComparison creates a Validation using the given require
// comparison assertion function.
func RequireComparison(fn require.ComparisonAssertionFunc, expected interface{}) Validation {
	if invertArgs(fn) {
		return func(t *testing.T, actual interface{}, messages ...interface{}) {
			fn(t, actual, expected, messages...)
		}
	}
	return func(t *testing.T, actual interface{}, messages ...interface{}) {
		fn(t, expected, actual, messages...)
	}
}

// RequireValue creates a Validation using the given require
// value assertion function.
func RequireValue(fn require.ValueAssertionFunc) Validation {
	return func(t *testing.T, actual interface{}, messages ...interface{}) {
		fn(t, actual, messages...)
	}
}

// invertArgs determines if the comparison assertion function takes
// its arguments in reverse order.
func invertArgs(fn interface{}) bool {
	invertFuncs := []interface{}{
		assert.Contains,
		assert.NotContains,
		require.Contains,
		require.NotContains,
		//assertext.ContainsOneOf,
		//requireext.ContainsOneOf,
	}
	// Ref: https://stackoverflow.com/a/34901677
	baFuncStr := fmt.Sprintf("%v", fn)
	for _, invertFunc := range invertFuncs {
		if baFuncStr == fmt.Sprintf("%v", invertFunc) {
			return true
		}
	}
	return false
}
