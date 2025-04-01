// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
)

func TestPlanRbacEnabledGroupIds(t *testing.T) {
	t.Parallel()

	tenantId := "2492e7f7-df5d-4f17-95dc-63528774e820"
	adminIds := []string{"59218b02-7421-4e2d-840a-37ce0d676afa", "498afef2-ef42-4099-88f2-4138976df67f"}

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "rbac-enabled"
	variables["rbac_aad_enabled"] = true
	variables["rbac_aad_tenant_id"] = tenantId
	variables["rbac_aad_admin_group_object_ids"] = adminIds

	tests := map[string]helpers.TestCase{
		"aadRbacExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control}",
			AssertFunction:    assert.NotEqual,
		},
		"aadRbacTenant": {
			Expected:          tenantId,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].tenant_id}",
		},
		"aadRbacAdminIDs": {
			Expected:          `["` + adminIds[0] + `","` + adminIds[1] + `"]`,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].admin_group_object_ids}",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

func TestPlanRbacEnabledNoTenant(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "rbac-no-tenant"
	variables["rbac_aad_enabled"] = true

	_, err := helpers.InitPlanWithVariables(t, variables)
	assert.ErrorContains(t, err, "Missing required argument")
}
