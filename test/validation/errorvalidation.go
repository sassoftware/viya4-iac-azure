/*
 * Copyright (c) 2020-2022, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
 */

// Package validation ...
package validation

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// An ErrorValidation is a function that executes an error validation check.
type ErrorValidation func(t *testing.T, actual error, messages ...interface{})

// ErrorValidations houses a list of Validation.
type ErrorValidations []ErrorValidation

// Execute loops through each ErrorValidation and runs its Execute.
func (errorValidations ErrorValidations) Execute(t *testing.T, actual error, messages ...interface{}) {
	for _, errorValidation := range errorValidations {
		errorValidation(t, actual, messages...)
	}
}

// ErrorAssert creates an ErrorValidation using the given assert
// error assertion function.
func ErrorAssert(fn assert.ErrorAssertionFunc) ErrorValidation {
	return func(t *testing.T, actual error, messages ...interface{}) {
		fn(t, actual, messages...)
	}
}

// ErrorRequire creates an ErrorValidation using the given require
// error assertion function.
func ErrorRequire(fn require.ErrorAssertionFunc) ErrorValidation {
	return func(t *testing.T, actual error, messages ...interface{}) {
		fn(t, actual, messages...)
	}
}
