/*
 * Copyright (c) 2020-2022, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
 */

// Package validation ...
package validation

import (
	"testing"
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
