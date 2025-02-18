//go:build integration_plan_unit_tests

package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

const TENANT_ID = "2492e7f7-df5d-4f17-95dc-63528774e820"

func TestRbacVariables(t *testing.T) {
	t.Parallel()

	// Initialize the variables map
	variables := getDefaultPlanVars(t)

	// Set RBAC to true
	variables["rbac_aad_tenant_id"] = TENANT_ID
	variables["rbac_aad_enabled"] = true

	plan := initPlanWithVariables(t, variables)

	plannedMapName := "module.aks.azurerm_kubernetes_cluster.aks"
	ids := getValueFromResourcePlannedValuesMap(plan, plannedMapName, "azure_active_directory_role_based_access_control.admin_group_object_ids")
	assert.Nil(t, ids.Value())
	enabled := getValueFromResourcePlannedValuesMap(plan, plannedMapName, "azure_active_directory_role_based_access_control.azure_rbac_enabled")
	assert.False(t, enabled.Bool())
}
