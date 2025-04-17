package defaultapply

import (
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"os"
	"test/helpers"
	"testing"
)

func testApplyVirtualMachine(t *testing.T, plan *terraform.PlanStruct) {
	resourceMapName := "azurerm_resource_group.aks_rg[0]"
	nfsResourceMapName := "module.nfs[0].azurerm_linux_virtual_machine.vm"
	jumpResourceMapName := "module.jump[0].azurerm_linux_virtual_machine.vm"

	resourceGroupName := helpers.RetrieveFromPlan(plan, resourceMapName, "name")()
	nfsVmName := helpers.RetrieveFromPlan(plan, nfsResourceMapName, "name")()
	jumpVmName := helpers.RetrieveFromPlan(plan, jumpResourceMapName, "name")()

	vmList, err := azure.ListVirtualMachinesForResourceGroupE(resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}

	nfsVM := azure.GetVirtualMachine(t, nfsVmName, resourceGroupName, os.Getenv("TF_VAR_subscription_id"))

	tests := map[string]helpers.ApplyTestCase{
		"vmsLengthTest": {
			Expected: len(vmList),
			Actual:   2,
		},
		"vmsContainsNsfTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.name}"),
			Actual:            vmList,
			AssertFunction:    assert.Contains,
		},
		"vmsContainsJumpTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, jumpResourceMapName, "{$.name}"),
			Actual:            vmList,
			AssertFunction:    assert.Contains,
		},
		"nfsVmExistsTest": {
			Expected:        "true",
			ActualRetriever: helpers.RetrieveVMExists(resourceGroupName, nfsVmName),
			Message:         "NFS VM does not exist",
		},
		"nfsVmAdminTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.admin_username}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "OsProfile", "AdminUsername"),
			Message:           "Nfs VM admin username is incorrect",
		},
		"nfsAllowedExtensionOperationsTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.allow_extension_operations}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "OsProfile", "AllowExtensionOperations"),
			Message:           "Nfs VM allow extension operations is incorrect",
		},
		"nfsComputerNameTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.computer_name}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "OsProfile", "ComputerName"),
			Message:           "Nfs VM computer name is nil",
		},
		"nfsDisablePasswordAuthTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.disable_password_authentication}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "OsProfile", "LinuxConfiguration", "DisablePasswordAuthentication"),
			Message:           "Nfs VM computer name is nil",
		},
		"nfsIdTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromVirtualMachine(nfsVM, "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "Nfs VM ID is nil",
		},
		"nfsLocationTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.location}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "Location"),
			Message:           "Nfs VM location is incorrect",
		},
		"nfsNetworkInterfaceIDsTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.network_interface_ids}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "NetworkProfile", "NetworkInterfaces"),
			Message:           "Nfs VM network interface IDs are nil",
		},
		"nfsPlatformFaultDomainTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromVirtualMachine(nfsVM, "InstanceView", "PlatformFaultDomain"),
			Message:         "Nfs VM platform fault domain should return nil",
		},
		"nfsPriorityTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.priority}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "Priority"),
			Message:           "Nfs VM priority is incorrect",
		},
		"nfsProvisionVMAgentTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.provision_vm_agent}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "OsProfile", "LinuxConfiguration", "ProvisionVMAgent"),
			Message:           "Nfs Provision VM Agent is incorrect",
		},
		"nfsSizeTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.size}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "HardwareProfile", "VMSize"),
			Message:           "Nfs VM size is incorrect",
		},
		"nfsUltraSSDEnabledTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.additional_capabilities[0].ultra_ssd_enabled}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "AdditionalCapabilities", "UltraSSDEnabled"),
			Message:           "Nfs VM ultra SSD enabled is incorrect",
		},
		"nfsCachingTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.os_disk[0].disk_size_gb}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "OsDisk", "DiskSizeGB"),
			Message:           "Nfs VM caching is incorrect",
		},
		"nfsOSDiskIdTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "OsDisk", "ManagedDisk", "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "Nfs VM OS disk ID is nil",
		},
		"nfsOSDiskNameTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "OsDisk", "Name"),
			AssertFunction:  assert.NotEqual,
			Message:         "Nfs VM OS disk name is nil",
		},
		"nfsStorageAccountTypeTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.os_disk[0].storage_account_type}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "OsDisk", "ManagedDisk", "StorageAccountType"),
			Message:           "Nfs VM storage account type is incorrect",
		},
		"nfsWriteAcceleratorEnabledTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.os_disk[0].write_accelerator_enabled}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "OsDisk", "WriteAcceleratorEnabled"),
			Message:           "Nfs VM write accelerator enabled is incorrect",
		},
		"nfsOfferTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.source_image_reference[0].offer}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "ImageReference", "Offer"),
			Message:           "Nfs VM offer is incorrect",
		},
		"nfsPublisherTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.source_image_reference[0].publisher}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "ImageReference", "Publisher"),
			Message:           "Nfs VM publisher is incorrect",
		},
		"nfsSkuTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.source_image_reference[0].sku}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "ImageReference", "Sku"),
			Message:           "Nfs VM sku is incorrect",
		},
		"nfsVersionTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, nfsResourceMapName, "{$.source_image_reference[0].version}"),
			ActualRetriever:   helpers.RetrieveFromVirtualMachine(nfsVM, "StorageProfile", "ImageReference", "Version"),
			Message:           "Nfs VM Version is incorrect",
		},
		"jumpVmExistsTest": {
			Expected:        "true",
			ActualRetriever: helpers.RetrieveVMExists(resourceGroupName, jumpVmName),
			Message:         "NFS VM does not exist",
		},
	}

	helpers.RunApplyTests(t, tests)
}
