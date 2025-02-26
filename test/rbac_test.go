package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	RBAC_STATEFUL_SOURCE = "module.aks.azurerm_kubernetes_cluster.aks"
	TENANT_ID            = "2492e7f7-df5d-4f17-95dc-63528774e820"
)

var ADMIN_IDS = []string{
	"59218b02-7421-4e2d-840a-37ce0d676afa",
	"498afef2-ef42-4099-88f2-4138976df67f",
}

func TestDefaultRbacEnabledGroupIds(t *testing.T) {
	tests := map[string]testCase{
		"aadRbacExists": {
			expected:          `nil`,
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.azure_active_directory_role_based_access_control}",
			assertFunction:    assert.NotEqual,
		},
		"aadRbacTenant": {
			expected:          TENANT_ID,
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].tenant_id}",
		},
		"aadRbacAdminIDs": {
			expected:          `["` + ADMIN_IDS[0] + `","` + ADMIN_IDS[1] + `"]`,
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].admin_group_object_ids}",
		},
	}

	// Initialize the default variables map
	variables := getDefaultPlanVars(t)

	// Set RBAC to true
	variables["rbac_aad_enabled"] = true

	// rbac_aad_tenant_id is required
	variables["rbac_aad_tenant_id"] = TENANT_ID

	// set the rbac_aad_admin_group_object_ids property
	variables["rbac_aad_admin_group_object_ids"] = ADMIN_IDS

	// Generate the plan
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	// Run the tests
	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestDefaultRbacEnabledNoTenant(t *testing.T) {
	t.Parallel()

	// Initialize the default variables map
	variables := getDefaultPlanVars(t)

	// Set RBAC to true
	variables["rbac_aad_enabled"] = true

	_, err := initPlanWithVariables(t, variables)
	assert.ErrorContains(t, err, "Missing required argument")
}
