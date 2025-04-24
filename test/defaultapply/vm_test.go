// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultapply

import (
	"fmt"
	"os"
	"test/helpers"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testApplyVirtualMachine(t *testing.T, plan *terraform.PlanStruct) {
	resourceGroupName := helpers.RetrieveFromPlan(plan, "azurerm_resource_group.aks_rg[0]", "{$.name}")()

	// validate virtual machine resources from the cloud provider match the plan
	testVMList(t, plan, resourceGroupName)
	testVM(t, plan, resourceGroupName, "nfs")
	testVM(t, plan, resourceGroupName, "jump")
}

func testVMList(t *testing.T, plan *terraform.PlanStruct, resourceGroupName string) {
	nfsVmName := helpers.RetrieveFromPlan(plan, "module.nfs[0].azurerm_linux_virtual_machine.vm", "{$.name}")()
	jumpVmName := helpers.RetrieveFromPlan(plan, "module.jump[0].azurerm_linux_virtual_machine.vm", "{$.name}")()

	vmList, err := azure.ListVirtualMachinesForResourceGroupE(resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}

	tests := map[string]helpers.ApplyTestCase{
		"vmsLengthTest": {
			Expected: len(vmList),
			Actual:   2,
		},
		"vmsContainNsfTest": {
			Expected:       nfsVmName,
			Actual:         vmList,
			AssertFunction: assert.Contains,
		},
		"vmsContainJumpTest": {
			Expected:       jumpVmName,
			Actual:         vmList,
			AssertFunction: assert.Contains,
		},
	}

	helpers.RunApplyTests(t, tests)
}

func testVM(t *testing.T, plan *terraform.PlanStruct, resourceGroupName string, prefix string) {
	vmResourceMapName := fmt.Sprintf("module.%s[0].azurerm_linux_virtual_machine.vm", prefix)
	vmName := helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.name}")()
	virtualMachine, err := azure.GetVirtualMachineE(vmName, resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}

	tests := map[string]helpers.ApplyTestCase{
		prefix + "VmExistsTest": {
			Expected:       nil,
			Actual:         virtualMachine,
			AssertFunction: assert.NotEqual,
			Message:        "VM does not exist",
		},
		prefix + "VmAdminTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.admin_username}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "OsProfile", "AdminUsername"),
			Message:           "VM admin username is incorrect",
		},
		prefix + "AllowedExtensionOperationsTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.allow_extension_operations}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "OsProfile", "AllowExtensionOperations"),
			Message:           "VM allow extension operations is incorrect",
		},
		prefix + "ComputerNameTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "OsProfile", "ComputerName"),
			AssertFunction:  assert.NotEqual,
			Message:         "VM computer name is nil",
		},
		prefix + "DisablePasswordAuthTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.disable_password_authentication}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "OsProfile", "LinuxConfiguration", "DisablePasswordAuthentication"),
			Message:           "VM DisablePasswordAuthTest is incorrect",
		},
		prefix + "IdTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(virtualMachine, "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "VM ID is nil",
		},
		prefix + "LocationTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.location}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "Location"),
			Message:           "VM location is incorrect",
		},
		prefix + "NetworkInterfaceIDsTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "NetworkProfile", "NetworkInterfaces"),
			AssertFunction:  assert.NotEqual,
			Message:         "VM network interface IDs are nil",
		},
		prefix + "PlatformFaultDomainTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "InstanceView", "PlatformFaultDomain"),
			Message:         "VM platform fault domain should return nil",
		},
		prefix + "PriorityTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.priority}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "Priority"),
			Message:           "VM priority is incorrect",
		},
		prefix + "ProvisionVMAgentTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.provision_vm_agent}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "OsProfile", "LinuxConfiguration", "ProvisionVMAgent"),
			Message:           "Provision VM Agent is incorrect",
		},
		prefix + "SizeTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.size}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "HardwareProfile", "VMSize"),
			Message:           "VM size is incorrect",
		},
		prefix + "UltraSSDEnabledTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.additional_capabilities[0].ultra_ssd_enabled}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "AdditionalCapabilities", "UltraSSDEnabled"),
			Message:           "VM ultra SSD enabled is incorrect",
		},
		prefix + "CachingTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.os_disk[0].disk_size_gb}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "OsDisk", "DiskSizeGB"),
			Message:           "VM caching is incorrect",
		},
		prefix + "OSDiskIdTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "OsDisk", "ManagedDisk", "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "VM OS disk ID is nil",
		},
		prefix + "OSDiskNameTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "OsDisk", "Name"),
			AssertFunction:  assert.NotEqual,
			Message:         "VM OS disk name is nil",
		},
		prefix + "StorageAccountTypeTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.os_disk[0].storage_account_type}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "OsDisk", "ManagedDisk", "StorageAccountType"),
			Message:           "VM storage account type is incorrect",
		},
		prefix + "WriteAcceleratorEnabledTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.os_disk[0].write_accelerator_enabled}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "OsDisk", "WriteAcceleratorEnabled"),
			Message:           "VM write accelerator enabled is incorrect",
		},
		prefix + "OfferTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.source_image_reference[0].offer}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "ImageReference", "Offer"),
			Message:           "VM offer is incorrect",
		},
		prefix + "PublisherTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.source_image_reference[0].publisher}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "ImageReference", "Publisher"),
			Message:           "VM publisher is incorrect",
		},
		prefix + "SkuTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.source_image_reference[0].sku}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "ImageReference", "Sku"),
			Message:           "VM sku is incorrect",
		},
		prefix + "VersionTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vmResourceMapName, "{$.source_image_reference[0].version}"),
			ActualRetriever:   helpers.RetrieveFromStruct(virtualMachine, "VirtualMachineProperties", "StorageProfile", "ImageReference", "Version"),
			Message:           "VM Version is incorrect",
		},
	}

	helpers.RunApplyTests(t, tests)
}
