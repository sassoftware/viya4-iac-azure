package defaultapply

import (
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/stretchr/testify/assert"
	"os"
	"test/helpers"
	"testing"
)

func testApplyVM(t *testing.T, variables map[string]interface{}) {
	list, err := azure.ListVirtualMachinesForResourceGroupE(variables["resourceGroupName"].(string), os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}
	expectedVMCount := 2
	assert.Equal(t, expectedVMCount, len(list))
	assert.Contains(t, list, variables["nfsVMname"])
	assert.Contains(t, list, variables["jumpVMname"])

	nfsVMByRef := azure.GetVirtualMachine(t, variables["nfsVmName"].(string), variables["resourceGroupName"].(string), os.Getenv("TF_VAR_subscription_id"))

	tests := map[string]helpers.ApplyTestCase{
		"nfsVmExistsTest": {
			Expected:  "true",
			Retriever: helpers.RetrieveVMExists(variables, variables["nfsVmName"].(string)),
			Message:   "NFS VM does not exist",
		},
		"nfsVmAdminTest": {
			Expected:  variables["nfsVmAdmin"].(string),
			Retriever: helpers.RetrieveFromVirtualMachine(nfsVMByRef, "OsProfile.AdminUsername"),
			Message:   "Nfs VM admin username is incorrect",
		},
		"jumpVmExistsTest": {
			Expected:  "true",
			Retriever: helpers.RetrieveVMExists(variables, variables["jumpVmName"].(string)),
			Message:   "NFS VM does not exist",
		},
	}

	helpers.RunApplyTests(t, tests)
}

// todo checks to migrate
//func testNfsVM(t *testing.T) {
//actualAllowExtensionOperations := nfsVMByRef.OsProfile.AllowExtensionOperations
//t.Logf("expectedAllowExtensionOperations: %t", expectedAllowExtensionOperations)
//t.Logf("actualAllowExtensionOperations: %t", *actualAllowExtensionOperations)
//assert.Equal(t, expectedAllowExtensionOperations, *actualAllowExtensionOperations, "Nfs VM allow extension operations is incorrect")
//
//actualComputerName := nfsVMByRef.OsProfile.ComputerName
//assert.Nil(t, expectedComputerName, "Nfs VM computer name known after apply")
//t.Logf("actualComputerName: %s", *actualComputerName)
//assert.NotNil(t, actualComputerName, "Nfs VM computer name is nil")
//
//actualDisablePasswordAuthentication := nfsVMByRef.OsProfile.LinuxConfiguration.DisablePasswordAuthentication
//t.Logf("expectedDisablePasswordAuthentication: %t", expectedDisablePasswordAuthentication)
//t.Logf("actualDisablePasswordAuthentication: %t", *actualDisablePasswordAuthentication)
//assert.Equal(t, expectedDisablePasswordAuthentication, *actualDisablePasswordAuthentication, "Nfs VM disable password authentication is incorrect")
//
//actualID := nfsVMByRef.ID
//assert.Nil(t, expectedID, "Nfs VM ID known after apply")
//assert.NotNil(t, actualID, "Nfs VM ID is nil")
//
//actualLocation := nfsVMByRef.Location
//t.Logf("expectedLocation: %s", expectedLocation)
//t.Logf("actualLocation: %s", *actualLocation)
//assert.Equal(t, expectedLocation, *actualLocation, "Nfs VM location is incorrect")
//
//actualNetworkInterfaceIDs := nfsVMByRef.NetworkProfile.NetworkInterfaces
//assert.Nil(t, expectedNetworkInterfaceIDs, "Nfs VM network interface IDs known after apply")
//assert.NotNil(t, actualNetworkInterfaceIDs, "Nfs VM network interface IDs are nil")
//
//expectedPlatformFaultDomain := nfsVM.AttributeValues["platform_fault_domain"]
//actualPlatformFaultDomain := nfsVMByRef.InstanceView.PlatformFaultDomain
//t.Logf("expectedPlatformUpdateDomain: %d", expectedPlatformFaultDomain)
//assert.Nil(t, actualPlatformFaultDomain, "Nfs VM platform fault domain should return nil")
//
//// Check if the priority is correct
//expectedPriority := nfsVM.AttributeValues["priority"]
//actualPriority := nfsVMByRef.Priority
//t.Logf("expectedPriority: %s", expectedPriority)
//t.Logf("actualPriority: %s", string(actualPriority))
//assert.Equal(t, expectedPriority, string(actualPriority), "Nfs VM priority is incorrect")
//
//expectedProvisionVmAgent := nfsVM.AttributeValues["provision_vm_agent"]
//actualProvisionVmAgentLinux := nfsVMByRef.OsProfile.LinuxConfiguration.ProvisionVMAgent
//t.Logf("expectedProvisionVmAgent: %t", expectedProvisionVmAgent)
//t.Logf("actualProvisionVmAgentLinux: %t", *actualProvisionVmAgentLinux)
//
//expectedNfsVMSize := nfsVM.AttributeValues["size"]
//actualNfsVMSize := nfsVMByRef.HardwareProfile.VMSize
//t.Logf("expectedNfsVMSize: %s", expectedNfsVMSize)
//t.Logf("actualNfsVMSize: %s", string(actualNfsVMSize))
//assert.Equal(t, expectedNfsVMSize, string(actualNfsVMSize), "Nfs VM size is incorrect")
//
//expectedVirtualMachineID := nfsVM.AttributeValues["virtual_machine_id"]
//actualVirtualMachineID := nfsVMByRef.ID
//assert.Nil(t, expectedVirtualMachineID, "Nfs VM virtual machine ID known after apply")
//assert.NotNil(t, actualVirtualMachineID, "Nfs VM virtual machine ID is nil")
//
//expectedAdditionalCapabilities := nfsVM.AttributeValues["additional_capabilities"]
//
//expectedUltraSSDEnabled := expectedAdditionalCapabilities.([]interface{})[0].(map[string]interface{})["ultra_ssd_enabled"]
//actualUltraSSDEnabled := nfsVMByRef.AdditionalCapabilities.UltraSSDEnabled
//t.Logf("expectedUltraSSDEnabled: %t", expectedUltraSSDEnabled)
//t.Logf("actualUltraSSDEnabled: %t", *actualUltraSSDEnabled)
//assert.Equal(t, expectedUltraSSDEnabled, *actualUltraSSDEnabled, "Nfs VM ultra SSD enabled is incorrect")
//
//expectedOSDisk := nfsVM.AttributeValues["os_disk"]
//
//expectedCaching := expectedOSDisk.([]interface{})[0].(map[string]interface{})["caching"]
//actualCaching := nfsVMByRef.StorageProfile.OsDisk.Caching
//t.Logf("expectedCaching: %s", expectedCaching)
//t.Logf("actualCaching: %s", string(actualCaching))
//assert.Equal(t, expectedCaching, string(actualCaching), "Nfs VM caching is incorrect")
//
//expectedDiskSizeGBValue := expectedOSDisk.([]interface{})[0].(map[string]interface{})["disk_size_gb"]
//expectedDiskSizeGBFloat, ok := expectedDiskSizeGBValue.(float64) // Assuming the value is float64
//if !ok {
//	t.Errorf("expectedDiskSizeGB is not a float64, got: %T", expectedDiskSizeGBValue)
//}
//expectedDiskSizeGB := int32(expectedDiskSizeGBFloat)
//t.Logf("expectedDiskSizeGB: %d", expectedDiskSizeGB)
//
//actualDiskSizeGB := nfsVMByRef.StorageProfile.OsDisk.DiskSizeGB
//t.Logf("actualDiskSizeGB: %d", *actualDiskSizeGB)
//assert.Equal(t, expectedDiskSizeGB, *actualDiskSizeGB, "Nfs VM disk size GB is incorrect")
//
//expectedOSDiskID := expectedOSDisk.([]interface{})[0].(map[string]interface{})["id"]
//actualOSDiskID := nfsVMByRef.StorageProfile.OsDisk.ManagedDisk.ID
//assert.Nil(t, expectedOSDiskID, "Nfs VM OS disk ID known after apply")
//assert.NotNil(t, actualOSDiskID, "Nfs VM OS disk ID is nil")
//
//expectedOSDiskName := expectedOSDisk.([]interface{})[0].(map[string]interface{})["name"]
//actualOSDiskName := nfsVMByRef.StorageProfile.OsDisk.Name
//assert.Nil(t, expectedOSDiskName, "Nfs VM OS disk name known after apply")
//assert.NotNil(t, actualOSDiskName, "Nfs VM OS disk name is nil")
//
//expectedStorageAccountType := expectedOSDisk.([]interface{})[0].(map[string]interface{})["storage_account_type"]
//actualStorageAccountType := nfsVMByRef.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
//t.Logf("expectedStorageAccountType: %s", expectedStorageAccountType)
//t.Logf("actualStorageAccountType: %s", string(actualStorageAccountType))
//assert.Equal(t, expectedStorageAccountType, string(actualStorageAccountType), "Nfs VM storage account type is incorrect")
//
//expectedWriteAcceleratorEnabled := expectedOSDisk.([]interface{})[0].(map[string]interface{})["write_accelerator_enabled"]
//actualWriteAcceleratorEnabled := nfsVMByRef.StorageProfile.OsDisk.WriteAcceleratorEnabled
//t.Logf("expectedWriteAcceleratorEnabled: %t", expectedWriteAcceleratorEnabled)
//t.Logf("actualWriteAcceleratorEnabled: %t", *actualWriteAcceleratorEnabled)
//assert.Equal(t, expectedWriteAcceleratorEnabled, *actualWriteAcceleratorEnabled, "Nfs VM write accelerator enabled is incorrect")
//
//expectedSourceImageReference := nfsVM.AttributeValues["source_image_reference"]
//
//expectedOffer := expectedSourceImageReference.([]interface{})[0].(map[string]interface{})["offer"]
//actualOffer := nfsVMByRef.StorageProfile.ImageReference.Offer
//t.Logf("expectedOffer: %s", expectedOffer)
//t.Logf("actualOffer: %s", *actualOffer)
//assert.Equal(t, expectedOffer, *actualOffer, "Nfs VM offer is incorrect")
//
//expectedPublisher := expectedSourceImageReference.([]interface{})[0].(map[string]interface{})["publisher"]
//actualPublisher := nfsVMByRef.StorageProfile.ImageReference.Publisher
//t.Logf("expectedPublisher: %s", expectedPublisher)
//t.Logf("actualPublisher: %s", *actualPublisher)
//assert.Equal(t, expectedPublisher, *actualPublisher, "Nfs VM publisher is incorrect")
//
//expectedSku := expectedSourceImageReference.([]interface{})[0].(map[string]interface{})["sku"]
//actualSku := nfsVMByRef.StorageProfile.ImageReference.Sku
//t.Logf("expectedSku: %s", expectedSku)
//t.Logf("actualSku: %s", *actualSku)
//assert.Equal(t, expectedSku, *actualSku, "Nfs VM sku is incorrect")
//
//expectedVersion := expectedSourceImageReference.([]interface{})[0].(map[string]interface{})["version"]
//actualVersion := nfsVMByRef.StorageProfile.ImageReference.Version
//t.Logf("expectedVersion: %s", expectedVersion)
//t.Logf("actualVersion: %s", *actualVersion)
//}
