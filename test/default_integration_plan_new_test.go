// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	defaultTests := map[string]testCase{
		"nodeVmAdminTest": {
			expected:          "azureuser",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.linux_profile[0].admin_username}",
		},
		"clusterEgressTypeTest": {
			expected:          "loadBalancer",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.network_profile[0].outbound_type}",
		},
		"networkPluginTest": {
			expected:          "kubenet",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.network_profile[0].network_plugin}",
		},
		"k8sVersionTest": {
			expected:          "1.30",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.kubernetes_version}",
		},
		"skuTierTest": {
			expected:          "Free",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.sku_tier}",
		},
		"supportPlanTest": {
			expected:          "KubernetesOfficial",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.support_plan}",
		},
		"userIdentityTest": {
			expected:          "",
			resourceMapName:   "azurerm_user_assigned_identity.uai[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"rbacTest": {
			expected:          `[]`,
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.azure_active_directory_role_based_access_control}",
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range defaultTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanNetwork(t *testing.T) {
	networkTests := map[string]testCase{
		"vnetTest": {
			expected:          `["192.168.0.0/16"]`,
			resourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
			attributeJsonPath: "{$.address_space}",
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range networkTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanStorage(t *testing.T) {
	storageTests := map[string]testCase{
		"userTest": {
			expected:          "nfsuser",
			resourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			attributeJsonPath: "{$.admin_username}",
		},
		"sizeTest": {
			expected:          "Standard_D4s_v5",
			resourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			attributeJsonPath: "{$.size}",
		},
		"vmNotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"vmZoneEmptyStrTest": {
			expected:          "",
			resourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			attributeJsonPath: "{$.vm_zone}",
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range storageTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestPlanNodePoolsNew(t *testing.T) {
	nodePoolTests := map[string]testCase{
		"nodeVmAdminTest": {
			expected:          "azureuser",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.linux_profile[0].admin_username}",
		},
		"defaultNodepoolVmTypeTest": {
			expected:          "Standard_E8s_v5",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.default_node_pool[0].vm_size}",
		},
		"defaultNodepoolOsDiskSizeTest": {
			expected:          "128",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.default_node_pool[0].os_disk_size_gb}",
		},
		"defaultNodepoolMaxPodsTest": {
			expected:          "110",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.default_node_pool[0].max_pods}",
		},
		"defaultNodepoolMinNodesTest": {
			expected:          "1",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.default_node_pool[0].min_count}",
		},
		"defaultNodepoolMaxNodesTest": {
			expected:          "5",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.default_node_pool[0].max_count}",
		},
		"defaultNodepoolAvailabilityZonesTest": {
			expected:          "[\"1\"]",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.default_node_pool[0].zones}",
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range nodePoolTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}
