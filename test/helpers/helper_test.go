// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"github.com/Azure/azure-sdk-for-go/services/compute/mgmt/2019-07-01/compute"
	"github.com/Azure/azure-sdk-for-go/services/resources/mgmt/2020-10-01/resources"
	"github.com/Azure/go-autorest/autorest/to"
	"github.com/stretchr/testify/assert"
	"testing"
)

// TestRetrieveFromStruct tests the RetrieveFromStruct function, ensuring that values are correctly retrieved and
// mapped to a string.
func TestRetrieveFromStruct(t *testing.T) {

	rg := &resources.Group{
		ID:       to.StringPtr("ID"),
		Name:     to.StringPtr("Name"),
		Location: to.StringPtr("Location"),
	}

	rgLocation := RetrieveFromStruct(rg, "Location")()
	assert.Equal(t, "Location", rgLocation)
	rgName := RetrieveFromStruct(rg, "Name")()
	assert.Equal(t, "Name", rgName)
	rgID := RetrieveFromStruct(rg, "ID")()
	assert.Equal(t, "ID", rgID)

	nfsVM := &compute.VirtualMachine{
		VirtualMachineProperties: &compute.VirtualMachineProperties{
			AdditionalCapabilities: &compute.AdditionalCapabilities{
				UltraSSDEnabled: to.BoolPtr(false),
			},
			HardwareProfile: &compute.HardwareProfile{
				VMSize: compute.VirtualMachineSizeTypesStandardDS2V2,
			},
			NetworkProfile: &compute.NetworkProfile{
				NetworkInterfaces: &[]compute.NetworkInterfaceReference{{
					ID: to.StringPtr("ID"),
				}, {
					ID: to.StringPtr("ID"),
				}},
			},
			OsProfile: &compute.OSProfile{
				AdminUsername:            to.StringPtr("nfsuser"),
				AllowExtensionOperations: to.BoolPtr(true),
				ComputerName:             to.StringPtr(""),
				LinuxConfiguration: &compute.LinuxConfiguration{
					DisablePasswordAuthentication: to.BoolPtr(true),
					ProvisionVMAgent:              to.BoolPtr(true),
				},
			},
			Priority: compute.Regular,
			StorageProfile: &compute.StorageProfile{
				OsDisk: &compute.OSDisk{
					DiskSizeGB:              to.Int32Ptr(64),
					Name:                    to.StringPtr("DiskName"),
					WriteAcceleratorEnabled: to.BoolPtr(false),
					ManagedDisk: &compute.ManagedDiskParameters{
						ID:                 to.StringPtr("ID"),
						StorageAccountType: compute.StorageAccountTypesStandardLRS,
					},
				},
				ImageReference: &compute.ImageReference{
					Offer:     to.StringPtr("0001-com-ubuntu-server-focal"),
					Publisher: to.StringPtr("Canonical"),
					Sku:       to.StringPtr("20_04-lts"),
					Version:   to.StringPtr("latest"),
				},
			},
		},
		Location: to.StringPtr("eastus"),
		ID:       to.StringPtr("ID"),
	}

	adminUsername := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "OsProfile", "AdminUsername")()
	assert.Equal(t, "nfsuser", adminUsername)
	allowExtensionOperations := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "OsProfile", "AllowExtensionOperations")()
	assert.Equal(t, "true", allowExtensionOperations)
	computerName := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "OsProfile", "ComputerName")()
	assert.Equal(t, "", computerName)
	disablePasswordAuthentication := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "OsProfile", "LinuxConfiguration", "DisablePasswordAuthentication")()
	assert.Equal(t, "true", disablePasswordAuthentication)
	provisionVMAgent := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "OsProfile", "LinuxConfiguration", "ProvisionVMAgent")()
	assert.Equal(t, "true", provisionVMAgent)
	location := RetrieveFromStruct(nfsVM, "Location")()
	assert.Equal(t, "eastus", location)
	networkInterfaces := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "NetworkProfile", "NetworkInterfaces")()
	assert.Equal(t, "not nil", networkInterfaces)
	priority := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "Priority")()
	assert.Equal(t, "Regular", priority)
	vmSize := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "HardwareProfile", "VMSize")()
	assert.Equal(t, "Standard_DS2_v2", vmSize)
	ultraSSDEnabled := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "AdditionalCapabilities", "UltraSSDEnabled")()
	assert.Equal(t, "false", ultraSSDEnabled)
	diskSizeGB := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "OsDisk", "DiskSizeGB")()
	assert.Equal(t, "64", diskSizeGB)
	managedDiskId := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "OsDisk", "ManagedDisk", "ID")()
	assert.Equal(t, "ID", managedDiskId)
	osDiskName := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "OsDisk", "Name")()
	assert.Equal(t, "DiskName", osDiskName)
	storageAccountType := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "OsDisk", "ManagedDisk", "StorageAccountType")()
	assert.Equal(t, "Standard_LRS", storageAccountType)
	writeAcceleratorEnabled := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "OsDisk", "WriteAcceleratorEnabled")()
	assert.Equal(t, "false", writeAcceleratorEnabled)
	offer := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "ImageReference", "Offer")()
	assert.Equal(t, "0001-com-ubuntu-server-focal", offer)
	publisher := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "ImageReference", "Publisher")()
	assert.Equal(t, "Canonical", publisher)
	sku := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "ImageReference", "Sku")()
	assert.Equal(t, "20_04-lts", sku)
	version := RetrieveFromStruct(nfsVM, "VirtualMachineProperties", "StorageProfile", "ImageReference", "Version")()
	assert.Equal(t, "latest", version)
}
