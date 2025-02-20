//go:build integration_plan_unit_tests

package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

const RBAC_STATEFUL_SOURCE = "module.aks.azurerm_kubernetes_cluster.aks"
const TENANT_ID = "2492e7f7-df5d-4f17-95dc-63528774e820"

func TestDefaultRbacEnabledGroupIds(t *testing.T) {
	t.Parallel()

	// Initialize the default variables map
	variables := getDefaultPlanVars(t)

	// Set RBAC to true
	variables["rbac_aad_enabled"] = true

	// rbac_aad_tenant_id is required
	variables["rbac_aad_tenant_id"] = TENANT_ID

	plan, err := initPlanWithVariables(t, variables)
	assert.NoError(t, err)

	// admin_group_object_ids default is null list(string)
	groupids, err := getJsonPathFromResourcePlannedValuesMap(t, plan, RBAC_STATEFUL_SOURCE, "{$..admin_group_object_ids}")
	assert.NoError(t, err)
	assert.Equal(t, "<nil>", groupids)
}

func TestDefaultRbacEnabledNoTennant(t *testing.T) {
	t.Parallel()

	// Initialize the default variables map
	variables := getDefaultPlanVars(t)

	// Set RBAC to true
	variables["rbac_aad_enabled"] = true

	_, err := initPlanWithVariables(t, variables)
	assert.ErrorContains(t, err, "Missing required argument")
}
