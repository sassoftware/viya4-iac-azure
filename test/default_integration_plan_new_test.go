// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package test

import (
	"fmt"
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
		"jumpVmSSHKey": {
			expected:          "<nil>",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.linux_profile[0].ssh_key[0].key_data}",
			assertFunction:    assert.NotEqual,
			message:           "The Jump VM machine type should be Standard_B2s",
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
		"vnet_subnetTest": {
			expected:          "",
			resourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
			attributeJsonPath: "{$.subnet[0].name}",
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
		"aksNetworkPolicyTest": {
			expected:          "",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.expressions.aks_network_policy.reference[0]}",
		},
		"aksNetworkPluginModeTest": {
			expected:          "",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.expressions.aks_network_plugin_mode.reference[0]}",
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

// Test the Node Pool's default variables when using the
// sample-input-defaults.tfvars file.
func TestPlanNodePools(t *testing.T) {
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

// Test the default additional nodepool variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanAdditionalNodePools(t *testing.T) {

	type nodepoolTestcase struct {
		expected map[string]attrTuple
	}

	nodepoolTests := map[string]nodepoolTestcase{
		"stateless": {
			expected: map[string]attrTuple{
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
			expected: map[string]attrTuple{
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
			expected: map[string]attrTuple{
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
			expected: map[string]attrTuple{
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

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range nodepoolTests {
		t.Run(name, func(t *testing.T) {
			resourceMapName := "module.node_pools[\"" + name + "\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"
			for attrName, attrTuple := range tc.expected {
				t.Run(attrName, func(t *testing.T) {
					runTest(t, testCase{
						expected:          attrTuple.expectedValue,
						resourceMapName:   resourceMapName,
						attributeJsonPath: attrTuple.jsonPath,
					}, plan)
				})
			}
		})
	}
}

// Test the default location variable when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default location variable from the CONFIG-VARS which in this case is "eastus"
// module.aks.data.azurerm_public_ip.cluster_public_ip[0] location is set after apply.
func TestPlanLocation(t *testing.T) {
	storageTests := map[string]testCase{
		"networkSecurityGroupLocationTest": {
			expected:          "eastus",
			resourceMapName:   "azurerm_network_security_group.nsg[0]",
			attributeJsonPath: "{$.location}",
		},
		"resourceGroupAKSRGLocationTest": {
			expected:          "eastus",
			resourceMapName:   "azurerm_resource_group.aks_rg[0]",
			attributeJsonPath: "{$.location}",
		},
		"userAssignedIdentityUAILocationTest": {
			expected:          "eastus",
			resourceMapName:   "azurerm_user_assigned_identity.uai[0]",
			attributeJsonPath: "{$.location}",
		},
		"kubernetesClusterAKSLocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.location}",
		},
		"jumpLinuxVirtualMachineVMLocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			attributeJsonPath: "{$.location}",
		},
		"jumpNetworkInterfaceVMNICLocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.jump[0].azurerm_network_interface.vm_nic",
			attributeJsonPath: "{$.location}",
		},
		"jumpPublicIPVMPIPLocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.jump[0].azurerm_public_ip.vm_ip[0]",
			attributeJsonPath: "{$.location}",
		},
		"nfsManagedDiskVMDataDisk0LocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
			attributeJsonPath: "{$.location}",
		},
		"nfsManagedDiskVMDataDisk1LocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
			attributeJsonPath: "{$.location}",
		},
		"nfsManagedDiskVMDataDisk2LocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
			attributeJsonPath: "{$.location}",
		},
		"nfsManagedDiskVMDataDisk3LocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
			attributeJsonPath: "{$.location}",
		},
		"nfsNetworkInterfaceVMNICLocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.nfs[0].azurerm_network_interface.vm_nic",
			attributeJsonPath: "{$.location}",
		},
		"virtualNetworkVNETLocationTest": {
			expected:          "eastus",
			resourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
			attributeJsonPath: "{$.location}",
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

// create_nfs_public_ip
// assert.Nil(t, nfsPublicIP, "NFS Public IP should not be created when create_nfs_public_ip=false")
func TestPlanNFSPublicIP(t *testing.T) {
	nfsIPTests := map[string]testCase{
		"nfsPublicIP": {
			expected:          `nil`,
			resourceMapName:   "module.nfs[0].azurerm_public_ip.vm_ip[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.Equal,
			message:           "NFS Public IP should not be created when create_nfs_public_ip=false",
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range nfsIPTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestPlanNFSDisk(t *testing.T) {
	nfsDiskTests := map[string]testCase{
		"nfsDataDisk0NotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "NFS Data Disk 0 should be created for NFS VM",
		},
		"raid_disk0_type": {
			expected:          "Standard_LRS",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
			attributeJsonPath: "{$.storage_account_type}",
			message:           "NFS Data Disk 0 should be created with Standard_LRS storage account type",
		},
		"disk0_size_gb0": {
			expected:          "256",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
			attributeJsonPath: "{$.disk_size_gb}",
			message:           "NFS Data Disk 0 should be created with 256 GB size",
		},
		"nfsDataDisk1NotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "NFS Data Disk 1 should be created for NFS VM",
		},
		"raid_disk1_type": {
			expected:          "Standard_LRS",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
			attributeJsonPath: "{$.storage_account_type}",
			message:           "NFS Data Disk 1 should be created with Standard_LRS storage account type",
		},
		"disk1_size_gb": {
			expected:          "256",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
			attributeJsonPath: "{$.disk_size_gb}",
			message:           "NFS Data Disk 1 should be created with 256 GB size",
		},
		"nfsDataDisk2NotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "NFS Data Disk 2 should be created for NFS VM",
		},
		"raid_disk2_type": {
			expected:          "Standard_LRS",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
			attributeJsonPath: "{$.storage_account_type}",
			message:           "NFS Data Disk 2 should be created with Standard_LRS storage account type",
		},
		"disk2_size_gb": {
			expected:          "256",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
			attributeJsonPath: "{$.disk_size_gb}",
			message:           "NFS Data Disk 2 should be created with 256 GB size",
		},
		"nfsDataDisk3NotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "NFS Data Disk 3 should be created for NFS VM",
		},
		"raid_disk3_type": {
			expected:          "Standard_LRS",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
			attributeJsonPath: "{$.storage_account_type}",
			message:           "NFS Data Disk 3 should be created with Standard_LRS storage account type",
		},
		"disk3_size_gb": {
			expected:          "256",
			resourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
			attributeJsonPath: "{$.disk_size_gb}",
			message:           "NFS Data Disk 3 should be created with 256 GB size",
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range nfsDiskTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Test the Outputs section when using the sample-input-defaults.tfvars file.
func TestPlanOutputs(t *testing.T) {
	variables := getDefaultPlanVars(t)
	outputsTests := map[string]testCase{
		"outputsLocation": {
			expected:        "eastus",
			retriever:       getOutputsFromPlan,
			resourceMapName: "location",
			assertFunction:  assert.Equal,
			message:         "Location should be set to eastus",
		},
		"outputsClusterApiMode": {
			expected:        "public",
			retriever:       getOutputsFromPlan,
			resourceMapName: "cluster_api_mode",
			assertFunction:  assert.Equal,
			message:         "Cluster API mode should be set to public",
		},
		"outputsJumpRwxFilestorePath": {
			expected:        "/viya-share",
			retriever:       getOutputsFromPlan,
			resourceMapName: "jump_rwx_filestore_path",
			assertFunction:  assert.Equal,
			message:         "Jump VM RWX Filestore Path should be set to /viya-share",
		},
		"outputsPrefix": {
			expected:        variables["prefix"],
			retriever:       getOutputsFromPlan,
			resourceMapName: "prefix",
			assertFunction:  assert.Contains,
			message:         fmt.Sprintf("Prefix should contain %s", variables["prefix"]),
		},
	}

	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range outputsTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}

}

// Test the general variables when using the sample-input-defaults.tfvars file.
func TestPlanGeneral(t *testing.T) {
	outputsTests := map[string]testCase{
		"kubeconfigCrbResourceNotNil": {
			expected:          "<nil>",
			resourceMapName:   "module.kubeconfig.kubernetes_cluster_role_binding.kubernetes_crb[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "The kubeconfig CRB resource should exist",
		},
		"kubeconfigSAResourceNotNil": {
			expected:          "<nil>",
			resourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "The kubeconfig Service Account resource should exist",
		},
		"jumpVmNotNil": {
			expected:          "<nil>",
			resourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "The Jump VM resource should exist",
		},
		"jumpVmPublicIpNotNil": {
			expected:          "<nil>",
			resourceMapName:   "module.jump[0].azurerm_public_ip.vm_ip[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "The Jump VM Public IP resource should exist",
		},
		"jumpVmEnablePublicStaticIp": {
			expected:          "Static",
			resourceMapName:   "module.jump[0].azurerm_public_ip.vm_ip[0]",
			attributeJsonPath: "{$.allocation_method}",
			assertFunction:    assert.Equal,
			message:           "The Jump VM Public IP resource should have a Static allocation method",
		},
		"jumpVmAdmin": {
			expected:          "jumpuser",
			resourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			attributeJsonPath: "{$.admin_username}",
			assertFunction:    assert.Equal,
			message:           "The Jump VM admin username should be jumpuser",
		},
		"jumpVmMachineType": {
			expected:          "Standard_B2s",
			resourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			attributeJsonPath: "{$.size}",
			assertFunction:    assert.Equal,
			message:           "The Jump VM machine type should be Standard_B2s",
		},
	}
	variables := getDefaultPlanVars(t)

	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range outputsTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestDefaultSubnets(t *testing.T) {
	type subnetTestcase struct {
		expected map[string]attrTuple
	}

	subnetTests := map[string]subnetTestcase{
		"aks": {
			expected: map[string]attrTuple{
				"prefixes":                                 {`["192.168.0.0/23"]`, "{$.address_prefixes}"},
				"serviceEndpoints":                         {`["Microsoft.Sql"]`, "{$.service_endpoints}"},
				"privateEndpointNetworkPolicies":           {`Enabled`, "{$.private_endpoint_network_policies}"},
				"privateLinkServiceNetworkPoliciesEnabled": {`false`, "{$.private_link_service_network_policies_enabled}"},
				"serviceDelegations":                       {``, "{$.service_delegations}"},
			},
		},
		"misc": {
			expected: map[string]attrTuple{
				"prefixes":                                 {`["192.168.2.0/24"]`, "{$.address_prefixes}"},
				"serviceEndpoints":                         {`["Microsoft.Sql"]`, "{$.service_endpoints}"},
				"privateEndpointNetworkPolicies":           {`Enabled`, "{$.private_endpoint_network_policies}"},
				"privateLinkServiceNetworkPoliciesEnabled": {`false`, "{$.private_link_service_network_policies_enabled}"},
				"serviceDelegations":                       {``, "{$.service_delegations}"},
			},
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range subnetTests {
		t.Run(name, func(t *testing.T) {
			resourceMapName := "module.vnet.azurerm_subnet.subnet[\"" + name + "\"]"
			for attrName, attrTuple := range tc.expected {
				t.Run(attrName, func(t *testing.T) {
					runTest(t, testCase{
						expected:          attrTuple.expectedValue,
						resourceMapName:   resourceMapName,
						attributeJsonPath: attrTuple.jsonPath,
					}, plan)
				})
			}
		})
	}
}
