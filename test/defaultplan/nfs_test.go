package defaultplan

import (
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
)

// create_nfs_public_ip
// assert.Nil(t, nfsPublicIP, "NFS Public IP should not be created when create_nfs_public_ip=false")
func TestPlanNFSPublicIP(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"nfsPublicIP": {
			Expected:          `nil`,
			ResourceMapName:   "module.nfs[0].azurerm_public_ip.vm_ip[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.Equal,
			Message:           "NFS Public IP should not be created when create_nfs_public_ip=false",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}

func TestPlanNFSDisk(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"nfsDataDisk0NotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "NFS Data Disk 0 should be created for NFS VM",
		},
		"raid_disk0_type": {
			Expected:          "Standard_LRS",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
			AttributeJsonPath: "{$.storage_account_type}",
			Message:           "NFS Data Disk 0 should be created with Standard_LRS storage account type",
		},
		"disk0_size_gb0": {
			Expected:          "256",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
			AttributeJsonPath: "{$.disk_size_gb}",
			Message:           "NFS Data Disk 0 should be created with 256 GB size",
		},
		"nfsDataDisk1NotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "NFS Data Disk 1 should be created for NFS VM",
		},
		"raid_disk1_type": {
			Expected:          "Standard_LRS",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
			AttributeJsonPath: "{$.storage_account_type}",
			Message:           "NFS Data Disk 1 should be created with Standard_LRS storage account type",
		},
		"disk1_size_gb": {
			Expected:          "256",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
			AttributeJsonPath: "{$.disk_size_gb}",
			Message:           "NFS Data Disk 1 should be created with 256 GB size",
		},
		"nfsDataDisk2NotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "NFS Data Disk 2 should be created for NFS VM",
		},
		"raid_disk2_type": {
			Expected:          "Standard_LRS",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
			AttributeJsonPath: "{$.storage_account_type}",
			Message:           "NFS Data Disk 2 should be created with Standard_LRS storage account type",
		},
		"disk2_size_gb": {
			Expected:          "256",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
			AttributeJsonPath: "{$.disk_size_gb}",
			Message:           "NFS Data Disk 2 should be created with 256 GB size",
		},
		"nfsDataDisk3NotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "NFS Data Disk 3 should be created for NFS VM",
		},
		"raid_disk3_type": {
			Expected:          "Standard_LRS",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
			AttributeJsonPath: "{$.storage_account_type}",
			Message:           "NFS Data Disk 3 should be created with Standard_LRS storage account type",
		},
		"disk3_size_gb": {
			Expected:          "256",
			ResourceMapName:   "module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
			AttributeJsonPath: "{$.disk_size_gb}",
			Message:           "NFS Data Disk 3 should be created with 256 GB size",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
