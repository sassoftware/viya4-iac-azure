// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"
)

// Test the default location variable when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default location variable from the CONFIG-VARS which in this case is "eastus"
// module.aks.data.azurerm_public_ip.cluster_public_ip[0] location is set after apply.
func TestPlanLocation(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"networkSecurityGroupLocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "azurerm_network_security_group.nsg[0]",
			AttributeJsonPath: "{$.location}",
		},
		"resourceGroupAKSRGLocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "azurerm_resource_group.aks_rg[0]",
			AttributeJsonPath: "{$.location}",
		},
		"userAssignedIdentityUAILocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "azurerm_user_assigned_identity.uai[0]",
			AttributeJsonPath: "{$.location}",
		},
		"kubernetesClusterAKSLocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.location}",
		},
		"jumpLinuxVirtualMachineVMLocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$.location}",
		},
		"jumpNetworkInterfaceVMNICLocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.jump[0].azurerm_network_interface.vm_nic",
			AttributeJsonPath: "{$.location}",
		},
		"jumpPublicIPVMPIPLocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.jump[0].azurerm_public_ip.vm_ip[0]",
			AttributeJsonPath: "{$.location}",
		},
		"nfsManagedDiskVMDataDisk0LocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
			AttributeJsonPath: "{$.location}",
		},
		"nfsManagedDiskVMDataDisk1LocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
			AttributeJsonPath: "{$.location}",
		},
		"nfsManagedDiskVMDataDisk2LocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
			AttributeJsonPath: "{$.location}",
		},
		"nfsManagedDiskVMDataDisk3LocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
			AttributeJsonPath: "{$.location}",
		},
		"nfsNetworkInterfaceVMNICLocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.nfs[0].azurerm_network_interface.vm_nic",
			AttributeJsonPath: "{$.location}",
		},
		"virtualNetworkVNETLocationTest": {
			Expected:          "eastus",
			ResourceMapName:   "module.vnet[0].azurerm_virtual_network.vnet[0]",
			AttributeJsonPath: "{$.location}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
