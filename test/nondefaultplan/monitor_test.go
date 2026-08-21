// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test Azure Monitor / OMS Agent: log analytics workspace, solution, diagnostic setting,
// and the AKS oms_agent block must all be present when create_aks_azure_monitor=true.
func TestPlanAzureMonitor(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "azure-monitor"
	variables["create_aks_azure_monitor"] = true

	tests := map[string]helpers.TestCase{
		"logAnalyticsWorkspaceExists": {
			Expected:          "nil",
			ResourceMapName:   "azurerm_log_analytics_workspace.viya4[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "Log Analytics workspace must be created when create_aks_azure_monitor=true",
		},
		"logAnalyticsWorkspaceSku": {
			Expected:          "PerGB2018",
			ResourceMapName:   "azurerm_log_analytics_workspace.viya4[0]",
			AttributeJsonPath: "{$.sku}",
			Message:           "Log Analytics workspace SKU must be PerGB2018",
		},
		"logAnalyticsSolutionExists": {
			Expected:          "nil",
			ResourceMapName:   "azurerm_log_analytics_solution.viya4[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "Log Analytics solution must be created when create_aks_azure_monitor=true",
		},
		"diagnosticSettingExists": {
			Expected:          "nil",
			ResourceMapName:   "azurerm_monitor_diagnostic_setting.audit[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "Monitor diagnostic setting must be created when create_aks_azure_monitor=true",
		},
		// oms_agent block is present on the AKS cluster when monitoring is enabled
		"aksOmsAgentPresent": {
			Expected:          "[]",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.oms_agent}",
			AssertFunction:    assert.NotEqual,
			Message:           "AKS oms_agent block must be present when create_aks_azure_monitor=true",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
