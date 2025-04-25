// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultapply

import (
	"test/helpers"
	"testing"
)

func TestApplyDefaultMain(t *testing.T) {
	// terrafrom init and apply using the default configuration
	terraformOptions, plan := helpers.InitAndApply(t, nil)

	// deferred cleanup routine for the resources created by the terrafrom init and apply after the test have been run
	defer helpers.DestroyDouble(t, terraformOptions)

	// Drop in new test cases here
	testApplyResourceGroup(t, plan)
	testApplyVirtualMachine(t, plan)
}
