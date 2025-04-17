package defaultplan

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func TestApplyVirtualMachine(t *testing.T) {
	t.Parallel()

	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../../examples/sample-input-defaults.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	//  add the required variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	variables["default_public_access_cidrs"] = os.Getenv("TF_VAR_public_cidrs")

	// Create a temporary plan file
	planFileName := "testplan-" + variables["prefix"].(string) + ".tfplan"
	planFilePath := filepath.Join(os.TempDir(), planFileName)
	defer os.Remove(planFilePath)

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../../", "")
	// Get the path to the parent folder for clean up
	tempTestFolderSlice := strings.Split(tempTestFolder, string(os.PathSeparator))
	tempTestFolderPath := strings.Join(tempTestFolderSlice[:len(tempTestFolderSlice)-1], string(os.PathSeparator))
	defer os.RemoveAll(tempTestFolderPath)

	// Set up Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         variables,
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	// Check if the required environment variables are set, fail the test run if not
	if os.Getenv("TF_VAR_client_id") == "" || os.Getenv("TF_VAR_client_secret") == "" || os.Getenv("TF_VAR_tenant_id") == "" || os.Getenv("TF_VAR_subscription_id") == "" || variables["default_public_access_cidrs"] == "" {
		t.Fatal("Environment variables TF_VAR_client_id, TF_VAR_client_secret, TF_VAR_tenant_id, TF_VAR_subscription_id, and TF_VAR_public_cidrs must be set")
	}

	// This will run `terraform init` and `terraform plan`
	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	// Grab resource attributes from the plan for azurerm_resource_group.aks_rg[0]
	resourceGroupName := plan.ResourcePlannedValuesMap["azurerm_resource_group.aks_rg[0]"].AttributeValues["name"]
	//resourceGroupName := "iadomi-rg"
	nfsVMname := plan.ResourcePlannedValuesMap["module.nfs[0].azurerm_linux_virtual_machine.vm"].AttributeValues["name"]
	//nfsVMname := "iadomi-nfs-vm"
	t.Logf("nfsVMname: %s", nfsVMname)
	jumpVMname := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_linux_virtual_machine.vm"].AttributeValues["name"]
	//jumpVMname := "iadomi-jump-vm"
	t.Logf("jumpVMname: %s", jumpVMname)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer DestroyResources(t, terraformOptions)

	// This will run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	list, err := azure.ListVirtualMachinesForResourceGroupE(resourceGroupName.(string), os.Getenv("TF_VAR_subscription_id"))
	//list, err := azure.ListVirtualMachinesForResourceGroupE(resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}
	expectedVMCount := 2
	assert.Equal(t, expectedVMCount, len(list))
	assert.Contains(t, list, nfsVMname)
	assert.Contains(t, list, jumpVMname)

	testNfsVM(t, plan, nfsVMname, resourceGroupName)
	testJumpVM(t, jumpVMname, resourceGroupName)

}

func testNfsVM(t *testing.T, plan *terraform.PlanStruct, nfsVMname interface{}, resourceGroupName interface{}) {
	//func testNfsVM(t *testing.T, plan *terraform.PlanStruct, nfsVMname string, resourceGroupName string) {

	// Check if the NFS VM exists
	nfsExists, err := azure.VirtualMachineExistsE(nfsVMname.(string), resourceGroupName.(string), os.Getenv("TF_VAR_subscription_id"))
	//nfsExists, err := azure.VirtualMachineExistsE(nfsVMname, resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}
	assert.True(t, nfsExists, "NFS VM does not exist")

	nfsVM := plan.ResourcePlannedValuesMap["module.nfs[0].azurerm_linux_virtual_machine.vm"]
	nfsVMByRef := azure.GetVirtualMachine(t, nfsVMname.(string), resourceGroupName.(string), os.Getenv("TF_VAR_subscription_id"))
	//nfsVMByRef := azure.GetVirtualMachine(t, nfsVMname, resourceGroupName, os.Getenv("TF_VAR_subscription_id"))

	// Check if the admin username is correct
	expectedAdminUsername := nfsVM.AttributeValues["admin_username"]
	actualAdminUsername := nfsVMByRef.OsProfile.AdminUsername
	t.Logf("expectedAdminUsername: %s", expectedAdminUsername)
	t.Logf("actualAdminUsername: %s", *actualAdminUsername)
	assert.Equal(t, expectedAdminUsername, *actualAdminUsername, "Nfs VM admin username is incorrect")

	// Check if the allow extension operations is correct
	expectedAllowExtensionOperations := nfsVM.AttributeValues["allow_extension_operations"]
	actualAllowExtensionOperations := nfsVMByRef.OsProfile.AllowExtensionOperations
	t.Logf("expectedAllowExtensionOperations: %t", expectedAllowExtensionOperations)
	t.Logf("actualAllowExtensionOperations: %t", *actualAllowExtensionOperations)
	assert.Equal(t, expectedAllowExtensionOperations, *actualAllowExtensionOperations, "Nfs VM allow extension operations is incorrect")

	// No Terratest function to check bypass platfrom safety checks on user schedule enabled

	// Check if computer name is not nill
	expectedComputerName := nfsVM.AttributeValues["computer_name"]
	actualComputerName := nfsVMByRef.OsProfile.ComputerName
	assert.Nil(t, expectedComputerName, "Nfs VM computer name known after apply")
	t.Logf("actualComputerName: %s", *actualComputerName)
	assert.NotNil(t, actualComputerName, "Nfs VM computer name is nil")

	// Check if the custom data is correct
	// This seemed to be the way to access the custom data but could not get the test to work; will need to investigate further
	// expectedCustomData := nfsVM.AttributeValues["custom_data"]
	// t.Logf("expectedCustomData: %s", expectedCustomData)
	// actualCustomData := nfsVMByRef.OsProfile.CustomData
	// t.Logf("actualCustomData: %s", *actualCustomData)
	//assert.Equal(t, expectedCustomData, *actualCustomData, "Nfs VM custom data is incorrect")

	// Check if the disable password authentication is correct
	expectedDisablePasswordAuthentication := nfsVM.AttributeValues["disable_password_authentication"]
	actualDisablePasswordAuthentication := nfsVMByRef.OsProfile.LinuxConfiguration.DisablePasswordAuthentication
	t.Logf("expectedDisablePasswordAuthentication: %t", expectedDisablePasswordAuthentication)
	t.Logf("actualDisablePasswordAuthentication: %t", *actualDisablePasswordAuthentication)
	assert.Equal(t, expectedDisablePasswordAuthentication, *actualDisablePasswordAuthentication, "Nfs VM disable password authentication is incorrect")

	// No Terratest function to check disk controller type

	// No Terratest function to check encryption at host enabled

	// Check if the check encryption at host enabled is correct
	// This seemed to be they way to access the encryption at host enabled but could not get the test to work; will need to investigate further
	// Observation: There are some attributes that will return nil if the initialization of that attribute is set to false in the plan.
	// The attribute will no longer be nil once set to true and back to false.
	// expectedEncryptionAtHostEnabled := nfsVM.AttributeValues["encryption_at_host_enabled"]
	// actualEncryptionAtHostEnabled := nfsVMByRef.StorageProfile.OsDisk.EncryptionSettings.Enabled
	// t.Logf("expectedEncryptionAtHostEnabled: %t", expectedEncryptionAtHostEnabled)
	// t.Logf("actualEncryptionAtHostEnabled: %t", *actualEncryptionAtHostEnabled)
	// assert.Equal(t, expectedEncryptionAtHostEnabled, *actualEncryptionAtHostEnabled, "Nfs VM encryption at host enabled is incorrect")

	// No Terratest function to check extensions time budget

	// Check if id is not nill
	expectedID := nfsVM.AttributeValues["id"]
	actualID := nfsVMByRef.ID
	assert.Nil(t, expectedID, "Nfs VM ID known after apply")
	assert.NotNil(t, actualID, "Nfs VM ID is nil")

	// Check if location is correct
	expectedLocation := nfsVM.AttributeValues["location"]
	actualLocation := nfsVMByRef.Location
	t.Logf("expectedLocation: %s", expectedLocation)
	t.Logf("actualLocation: %s", *actualLocation)
	assert.Equal(t, expectedLocation, *actualLocation, "Nfs VM location is incorrect")

	// Check if check max bid price is correct
	// This seemed to be the way to access the max bid price but could not get the test to work; will need to investigate further
	// Observation: An intial setting of -1 in the plan will return nil in the actual value.
	// The attribute will no longer be nil once set to a value.
	// expectedMaxBidPrice := nfsVM.AttributeValues["max_bid_price"]
	// actualMaxBidPrice := nfsVMByRef.BillingProfile.MaxPrice
	// t.Logf("expectedMaxBidPrice: %d", expectedMaxBidPrice)
	// assert.Nil(t, actualMaxBidPrice, "Nfs VM max bid price should return nil")

	// Check if network interface IDs is not nill
	expectedNetworkInterfaceIDs := nfsVM.AttributeValues["network_interface_ids"]
	actualNetworkInterfaceIDs := nfsVMByRef.NetworkProfile.NetworkInterfaces
	assert.Nil(t, expectedNetworkInterfaceIDs, "Nfs VM network interface IDs known after apply")
	// if actualNetworkInterfaceIDs != nil {
	// 	for _, nic := range *actualNetworkInterfaceIDs {
	// 		t.Logf("Network Interface ID: %s", *nic.ID)
	// 	}
	// } else {
	// 	t.Log("actualNetworkInterfaceIDs is nil")
	// }
	assert.NotNil(t, actualNetworkInterfaceIDs, "Nfs VM network interface IDs are nil")

	// No Terratest function to check patch assesment mode

	// No Terratest function to check patch mode

	// Check if the platform fault domain is correct
	// Observation: An intial setting of -1 in the plan will return nil in the actual value.
	// The attribute will no longer be nil once set to a value.
	expectedPlatformFaultDomain := nfsVM.AttributeValues["platform_fault_domain"]
	actualPlatformFaultDomain := nfsVMByRef.InstanceView.PlatformFaultDomain
	t.Logf("expectedPlatformUpdateDomain: %d", expectedPlatformFaultDomain)
	assert.Nil(t, actualPlatformFaultDomain, "Nfs VM platform fault domain should return nil")

	// Check if the priority is correct
	expectedPriority := nfsVM.AttributeValues["priority"]
	actualPriority := nfsVMByRef.Priority
	t.Logf("expectedPriority: %s", expectedPriority)
	t.Logf("actualPriority: %s", string(actualPriority))
	assert.Equal(t, expectedPriority, string(actualPriority), "Nfs VM priority is incorrect")

	// Check if the private IP address is correct
	// Could not seem to find terratest function to check the private IP address for vm resource

	// Check if the private IP addresses is correct
	// Could not seem to find terratest function to check the private IP addresses for vm resource

	// Check if provision vm agent is correct
	expectedProvisionVmAgent := nfsVM.AttributeValues["provision_vm_agent"]
	actualProvisionVmAgentLinux := nfsVMByRef.OsProfile.LinuxConfiguration.ProvisionVMAgent
	t.Logf("expectedProvisionVmAgent: %t", expectedProvisionVmAgent)
	t.Logf("actualProvisionVmAgentLinux: %t", *actualProvisionVmAgentLinux)

	// Check if the public IP address is correct
	// Could not seem to find terratest function to check the public IP address for vm resource

	// Check if the public IP addresses is correct
	// Could not seem to find terratest function to check the public IP addresses for vm resource

	// Check if the NFS VM size is correct
	expectedNfsVMSize := nfsVM.AttributeValues["size"]
	actualNfsVMSize := nfsVMByRef.HardwareProfile.VMSize
	t.Logf("expectedNfsVMSize: %s", expectedNfsVMSize)
	t.Logf("actualNfsVMSize: %s", string(actualNfsVMSize))
	assert.Equal(t, expectedNfsVMSize, string(actualNfsVMSize), "Nfs VM size is incorrect")

	// Check if the virtual machine id is not nill
	expectedVirtualMachineID := nfsVM.AttributeValues["virtual_machine_id"]
	actualVirtualMachineID := nfsVMByRef.ID
	assert.Nil(t, expectedVirtualMachineID, "Nfs VM virtual machine ID known after apply")
	// if actualVirtualMachineID != nil {
	// 	t.Logf("actualVirtualMachineID: %s", *actualVirtualMachineID)
	// } else {
	// 	t.Log("actualVirtualMachineID is nil")
	// }
	assert.NotNil(t, actualVirtualMachineID, "Nfs VM virtual machine ID is nil")

	// No terratest function to check the vm agent platform updates enabled

	// Check if additional capapbilities is correct
	expectedAdditionalCapabilities := nfsVM.AttributeValues["additional_capabilities"]

	// No Terratest function to check hibernation enabled

	// Check if ultra SSD enabled is correct
	expectedUltraSSDEnabled := expectedAdditionalCapabilities.([]interface{})[0].(map[string]interface{})["ultra_ssd_enabled"]
	actualUltraSSDEnabled := nfsVMByRef.AdditionalCapabilities.UltraSSDEnabled
	t.Logf("expectedUltraSSDEnabled: %t", expectedUltraSSDEnabled)
	t.Logf("actualUltraSSDEnabled: %t", *actualUltraSSDEnabled)
	assert.Equal(t, expectedUltraSSDEnabled, *actualUltraSSDEnabled, "Nfs VM ultra SSD enabled is incorrect")

	//Check if os disk is correct
	expectedOSDisk := nfsVM.AttributeValues["os_disk"]

	// Check if caching is correct
	expectedCaching := expectedOSDisk.([]interface{})[0].(map[string]interface{})["caching"]
	actualCaching := nfsVMByRef.StorageProfile.OsDisk.Caching
	t.Logf("expectedCaching: %s", expectedCaching)
	t.Logf("actualCaching: %s", string(actualCaching))
	assert.Equal(t, expectedCaching, string(actualCaching), "Nfs VM caching is incorrect")

	// Check if disk size gb is correct
	expectedDiskSizeGBValue := expectedOSDisk.([]interface{})[0].(map[string]interface{})["disk_size_gb"]
	expectedDiskSizeGBFloat, ok := expectedDiskSizeGBValue.(float64) // Assuming the value is float64
	if !ok {
		t.Errorf("expectedDiskSizeGB is not a float64, got: %T", expectedDiskSizeGBValue)
	}
	expectedDiskSizeGB := int32(expectedDiskSizeGBFloat)
	t.Logf("expectedDiskSizeGB: %d", expectedDiskSizeGB)

	actualDiskSizeGB := nfsVMByRef.StorageProfile.OsDisk.DiskSizeGB
	t.Logf("actualDiskSizeGB: %d", *actualDiskSizeGB)
	assert.Equal(t, expectedDiskSizeGB, *actualDiskSizeGB, "Nfs VM disk size GB is incorrect")

	// Check if id is correct
	expectedOSDiskID := expectedOSDisk.([]interface{})[0].(map[string]interface{})["id"]
	actualOSDiskID := nfsVMByRef.StorageProfile.OsDisk.ManagedDisk.ID
	assert.Nil(t, expectedOSDiskID, "Nfs VM OS disk ID known after apply")
	//t.Logf("actualOSDiskID: %s", *actualOSDiskID)
	assert.NotNil(t, actualOSDiskID, "Nfs VM OS disk ID is nil")

	// Check if name is correct
	expectedOSDiskName := expectedOSDisk.([]interface{})[0].(map[string]interface{})["name"]
	actualOSDiskName := nfsVMByRef.StorageProfile.OsDisk.Name
	assert.Nil(t, expectedOSDiskName, "Nfs VM OS disk name known after apply")
	//t.Logf("actualOSDiskName: %s", *actualOSDiskName)
	assert.NotNil(t, actualOSDiskName, "Nfs VM OS disk name is nil")

	// Check if storage account type is correct
	expectedStorageAccountType := expectedOSDisk.([]interface{})[0].(map[string]interface{})["storage_account_type"]
	actualStorageAccountType := nfsVMByRef.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
	t.Logf("expectedStorageAccountType: %s", expectedStorageAccountType)
	t.Logf("actualStorageAccountType: %s", string(actualStorageAccountType))
	assert.Equal(t, expectedStorageAccountType, string(actualStorageAccountType), "Nfs VM storage account type is incorrect")

	// Check if write accelerator enabled is correct
	expectedWriteAcceleratorEnabled := expectedOSDisk.([]interface{})[0].(map[string]interface{})["write_accelerator_enabled"]
	actualWriteAcceleratorEnabled := nfsVMByRef.StorageProfile.OsDisk.WriteAcceleratorEnabled
	t.Logf("expectedWriteAcceleratorEnabled: %t", expectedWriteAcceleratorEnabled)
	t.Logf("actualWriteAcceleratorEnabled: %t", *actualWriteAcceleratorEnabled)
	assert.Equal(t, expectedWriteAcceleratorEnabled, *actualWriteAcceleratorEnabled, "Nfs VM write accelerator enabled is incorrect")

	//Check if source image reference is correct
	expectedSourceImageReference := nfsVM.AttributeValues["source_image_reference"]

	// Check if offer is correct
	expectedOffer := expectedSourceImageReference.([]interface{})[0].(map[string]interface{})["offer"]
	actualOffer := nfsVMByRef.StorageProfile.ImageReference.Offer
	t.Logf("expectedOffer: %s", expectedOffer)
	t.Logf("actualOffer: %s", *actualOffer)
	assert.Equal(t, expectedOffer, *actualOffer, "Nfs VM offer is incorrect")

	// Check if publisher is correct
	expectedPublisher := expectedSourceImageReference.([]interface{})[0].(map[string]interface{})["publisher"]
	actualPublisher := nfsVMByRef.StorageProfile.ImageReference.Publisher
	t.Logf("expectedPublisher: %s", expectedPublisher)
	t.Logf("actualPublisher: %s", *actualPublisher)
	assert.Equal(t, expectedPublisher, *actualPublisher, "Nfs VM publisher is incorrect")

	// Check if sku is correct
	expectedSku := expectedSourceImageReference.([]interface{})[0].(map[string]interface{})["sku"]
	actualSku := nfsVMByRef.StorageProfile.ImageReference.Sku
	t.Logf("expectedSku: %s", expectedSku)
	t.Logf("actualSku: %s", *actualSku)
	assert.Equal(t, expectedSku, *actualSku, "Nfs VM sku is incorrect")

	// Check if version is correct
	expectedVersion := expectedSourceImageReference.([]interface{})[0].(map[string]interface{})["version"]
	actualVersion := nfsVMByRef.StorageProfile.ImageReference.Version
	t.Logf("expectedVersion: %s", expectedVersion)
	t.Logf("actualVersion: %s", *actualVersion)

	// No Terratest function to check termination notification

}

func testJumpVM(t *testing.T, jumpVMname interface{}, resourceGroupName interface{}) {
	//func testJumpVM(t *testing.T, jumpVMname string, resourceGroupName string) {

	jumpExists, err := azure.VirtualMachineExistsE(jumpVMname.(string), resourceGroupName.(string), os.Getenv("TF_VAR_subscription_id"))
	//jumpExists, err := azure.VirtualMachineExistsE(jumpVMname, resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}
	assert.True(t, jumpExists, "Jump VM does not exist")
}

func DestroyResources(t *testing.T, terraformOptions *terraform.Options) {
	//Destroy the resources we created
	_, err := terraform.DestroyE(t, terraformOptions)
	if err != nil {
		//If the first destroy fails, try to destroy again
		_, out := terraform.DestroyE(t, terraformOptions)
		// If the second destroy fails, fail the test for further investigation
		if out != nil {
			t.Errorf("Error: %s\n", out)
		}
	}

	return
}
