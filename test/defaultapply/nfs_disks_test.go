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

func testApplyNFSDisks(t *testing.T, plan *terraform.PlanStruct) {
	resourceGroupName := helpers.RetrieveFromPlan(plan, "azurerm_resource_group.aks_rg[0]", "{$.name}")()
	subscriptionID := os.Getenv("TF_VAR_subscription_id")

	// disk_count is hardcoded to 4 in vms.tf; names follow format("{prefix}-nfs-disk%02d", index+1)
	for i := 0; i < 4; i++ {
		diskIndex := i
		diskResourceMapName := fmt.Sprintf("module.nfs[0].azurerm_managed_disk.vm_data_disk[%d]", diskIndex)
		diskName := helpers.RetrieveFromPlan(plan, diskResourceMapName, "{$.name}")()

		disk, err := azure.GetDiskE(diskName, resourceGroupName, subscriptionID)
		if err != nil {
			t.Errorf("Error getting NFS disk %s: %s\n", diskName, err)
			continue
		}

		diskLabel := fmt.Sprintf("disk%02d", diskIndex+1)

		tests := map[string]helpers.ApplyTestCase{
			diskLabel + "ExistsTest": {
				Expected:        "nil",
				ActualRetriever: helpers.RetrieveFromStruct(disk, "ID"),
				AssertFunction:  assert.NotEqual,
				Message:         fmt.Sprintf("NFS disk %s ID is nil", diskName),
			},
			diskLabel + "SizeTest": {
				ExpectedRetriever: helpers.RetrieveFromPlan(plan, diskResourceMapName, "{$.disk_size_gb}"),
				ActualRetriever:   helpers.RetrieveFromStruct(disk, "DiskProperties", "DiskSizeGB"),
				Message:           fmt.Sprintf("NFS disk %s size does not match plan", diskName),
			},
			diskLabel + "StateTest": {
				Expected:        "Attached",
				ActualRetriever: helpers.RetrieveFromStruct(disk, "DiskProperties", "DiskState"),
				Message:         fmt.Sprintf("NFS disk %s is not attached to the VM", diskName),
			},
		}

		helpers.RunApplyTests(t, tests)
	}
}
