// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultapply

import (
	"test/helpers"
	"testing"
)

// todo - add tests for non-default apply.  Overrides are currently for illustrative purposes only.
func TestApplyNonDefaultMain(t *testing.T) {
	// terraform init and apply using a non-default values in the plan
	overrides := make(map[string]interface{})
	overrides["kubernetes_version"] = "1.33.0"
	overrides["create_container_registry"] = true
	overrides["container_registry_admin_enabled"] = true
	overrides["container_registry_geo_replica_locs"] = []string{"southeastus5", "southeastus3"}
	overrides["rbac_aad_enabled"] = true
	overrides["storage_type"] = "ha"

	// deferred cleanup routine for the resources created by the terrafrom init and apply after the test have been run
	terraformOptions, _ := helpers.InitPlanAndApply(t, overrides)

	defer helpers.DestroyDouble(t, terraformOptions)

	// Drop in test cases here

}
