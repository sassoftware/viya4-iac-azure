// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"
)

// Test the Node Pool's default variables when using the
// sample-input-defaults.tfvars file.
func TestPlanNodePools(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"nodeVmAdminTest": {
			Expected:          "azureuser",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.linux_profile[0].admin_username}",
		},
		"defaultNodepoolVmTypeTest": {
			Expected:          "Standard_E8s_v5",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].vm_size}",
		},
		"defaultNodepoolOsDiskSizeTest": {
			Expected:          "128",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].os_disk_size_gb}",
		},
		"defaultNodepoolMaxPodsTest": {
			Expected:          "110",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].max_pods}",
		},
		"defaultNodepoolMinNodesTest": {
			Expected:          "1",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].min_count}",
		},
		"defaultNodepoolMaxNodesTest": {
			Expected:          "5",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].max_count}",
		},
		"defaultNodepoolAvailabilityZonesTest": {
			Expected:          "[\"1\"]",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.default_node_pool[0].zones}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}

// Test the default additional nodepool variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanAdditionalNodePools(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TupleTestCase{
		"stateless": {
			Expected: map[string]helpers.AttrTuple{
				"MachineType":       {`Standard_D4s_v5`, "{$.vm_size}"},
				"OsDiskSize":        {`200`, "{$.os_disk_size_gb}"},
				"MinNodes":          {`0`, "{$.min_count}"},
				"MaxNodes":          {`5`, "{$.max_count}"},
				"MaxPods":           {`110`, "{$.max_pods}"},
				"NodeTaints":        {`["workload.sas.com/class=stateless:NoSchedule"]`, "{$.node_taints}"},
				"NodeLabels":        {`{"workload.sas.com/class":"stateless"}`, "{$.node_labels}"},
				"AvailabilityZones": {`["1"]`, "{$.zones}"},
				"FipsEnabled":       {`false`, "{$.fips_enabled}"},
			},
		},
		"stateful": {
			Expected: map[string]helpers.AttrTuple{
				"MachineType":       {`Standard_D4s_v5`, "{$.vm_size}"},
				"OsDiskSize":        {`200`, "{$.os_disk_size_gb}"},
				"MinNodes":          {`0`, "{$.min_count}"},
				"MaxNodes":          {`3`, "{$.max_count}"},
				"MaxPods":           {`110`, "{$.max_pods}"},
				"NodeTaints":        {`["workload.sas.com/class=stateful:NoSchedule"]`, "{$.node_taints}"},
				"NodeLabels":        {`{"workload.sas.com/class":"stateful"}`, "{$.node_labels}"},
				"AvailabilityZones": {`["1"]`, "{$.zones}"},
				"FipsEnabled":       {`false`, "{$.fips_enabled}"},
			},
		},
		"cas": {
			Expected: map[string]helpers.AttrTuple{
				"MachineType":       {`Standard_E16ds_v5`, "{$.vm_size}"},
				"OsDiskSize":        {`200`, "{$.os_disk_size_gb}"},
				"MinNodes":          {`0`, "{$.min_count}"},
				"MaxNodes":          {`5`, "{$.max_count}"},
				"MaxPods":           {`110`, "{$.max_pods}"},
				"NodeTaints":        {`["workload.sas.com/class=cas:NoSchedule"]`, "{$.node_taints}"},
				"NodeLabels":        {`{"workload.sas.com/class":"cas"}`, "{$.node_labels}"},
				"AvailabilityZones": {`["1"]`, "{$.zones}"},
				"FipsEnabled":       {`false`, "{$.fips_enabled}"},
			},
		},
		"compute": {
			Expected: map[string]helpers.AttrTuple{
				"MachineType":       {`Standard_D4ds_v5`, "{$.vm_size}"},
				"OsDiskSize":        {`200`, "{$.os_disk_size_gb}"},
				"MinNodes":          {`1`, "{$.min_count}"},
				"MaxNodes":          {`5`, "{$.max_count}"},
				"MaxPods":           {`110`, "{$.max_pods}"},
				"NodeTaints":        {`["workload.sas.com/class=compute:NoSchedule"]`, "{$.node_taints}"},
				"NodeLabels":        {`{"launcher.sas.com/prepullImage":"sas-programming-environment","workload.sas.com/class":"compute"}`, "{$.node_labels}"},
				"AvailabilityZones": {`["1"]`, "{$.zones}"},
				"FipsEnabled":       {`false`, "{$.fips_enabled}"},
			},
		},
	}

	resourceMapNameFmt := "module.node_pools[\"%s\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"
	helpers.RunTupleTests(t, resourceMapNameFmt, tests, helpers.GetDefaultPlan(t))
}
