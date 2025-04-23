// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultapply

import (
	"test/helpers"
	"testing"
)

// todo - add tests for non-default apply.  Overrides are currently for illustrative purposes only.
func TestApplyMain(t *testing.T) {
	overrides := make(map[string]interface{})
	overrides["aks_azure_policy_enabled"] = true
	overrides["create_container_registry"] = true
	overrides["container_registry_admin_enabled"] = true
	overrides["container_registry_sku"] = "Premium"
	overrides["container_registry_geo_replica_locs"] = []string{"southeastus5", "southeastus3"}
	overrides["rbac_aad_enabled"] = true
	overrides["rbac_aad_tenant_id"] = "2492e7f7-df5d-4f17-95dc-63528774e820"
	overrides["rbac_aad_admin_group_object_ids"] = []string{"59218b02-7421-4e2d-840a-37ce0d676afa", "498afef2-ef42-4099-88f2-4138976df67f"}
	overrides["storage_type"] = "ha"

	terraformOptions, _ := helpers.InitAndApply(t, overrides)

	defer helpers.DestroyDouble(t, terraformOptions)

	// Drop in test cases here

}
