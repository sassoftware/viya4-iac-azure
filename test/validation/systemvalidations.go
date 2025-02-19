/*
 * Copyright (c) 2020-2022, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
 */

// Package validation ...
package validation

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// SystemValidations are the definitions for validating the result of
// an orchestration command execution.
type SystemValidations struct {
	// Args are the command line arguments to issue.
	Args []string

	Plan *terraform.PlanStruct

	PlanValidations Validations

	// ExecutionError indicates the validations to run against
	// the golang error returned by the command execution. For
	// successful runs, the recommended check is either
	// assert.NoError or require.NoError.
	ExecutionError ErrorValidations
}

// Execute runs the test.
func (sv *SystemValidations) Execute(t *testing.T) {
	sv.PlanValidations.Execute(t, sv.Plan, "Context: Plan")
}
