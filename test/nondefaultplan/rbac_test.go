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

func TestNonDefaultRbacEnabledWithTenant(t *testing.T) {
	t.Parallel()

	const TENANT_ID = "b1c14d5c-3625-45b3-a430-9552373a0c2f"

	tests := map[string]helpers.TestCase{
		"aadRbacExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control}",
			AssertFunction:    assert.NotEqual,
		},
		"aadAzureRbacEnabled": {
			Expected:          `false`,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].azure_rbac_enabled}",
		},
		"aadRbacTenant": {
			Expected:          TENANT_ID,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].tenant_id}",
		},
		"aadRbacAdminIDs": {
			Expected:          `null`,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].admin_group_object_ids}",
		},
	}

	// Initialize the default variables map
	variables := helpers.GetDefaultPlanVars(t)

	variables["prefix"] = "rbac-with-tenant"
	variables["rbac_aad_enabled"] = true
	// Set RBAC to true
	variables["rbac_aad_enabled"] = true

	variables["tenant_id"] = TENANT_ID

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

func TestNonDefaultAzureRbacEnabledWithTenant(t *testing.T) {
	t.Parallel()

	const TENANT_ID = "b1c14d5c-3625-45b3-a430-9552373a0c2f"

	tests := map[string]helpers.TestCase{
		"aadRbacExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control}",
			AssertFunction:    assert.NotEqual,
		},
		"aadAzureRbacEnabled": {
			Expected:          `true`,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].azure_rbac_enabled}",
		},
		"aadRbacTenant": {
			Expected:          TENANT_ID,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].tenant_id}",
		},
	}

	// Initialize the default variables map
	variables := helpers.GetDefaultPlanVars(t)

	variables["prefix"] = "rbac-azure-enabled"
	// Set RBAC to true
	variables["rbac_aad_enabled"] = true

	// Set Azure RBAC enabled to true
	variables["rbac_aad_azure_rbac_enabled"] = true

	variables["tenant_id"] = TENANT_ID

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

