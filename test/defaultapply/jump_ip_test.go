// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultapply

import (
	"os"
	"strings"
	"test/helpers"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testApplyJumpPublicIP(t *testing.T, plan *terraform.PlanStruct) {
	jumpIPResourceMapName := "module.jump[0].azurerm_public_ip.vm_ip[0]"
	ipName := helpers.RetrieveFromPlan(plan, jumpIPResourceMapName, "{$.name}")()
	resourceGroupName := helpers.RetrieveFromPlan(plan, "azurerm_resource_group.aks_rg[0]", "{$.name}")()
	subscriptionID := os.Getenv("TF_VAR_subscription_id")

	pip, err := azure.GetPublicIPAddressE(ipName, resourceGroupName, subscriptionID)
	if err != nil {
		t.Errorf("Error getting Jump VM public IP: %s\n", err)
		return
	}

	tests := map[string]helpers.ApplyTestCase{
		"jumpIPExistsTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(pip, "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "Jump VM public IP ID is nil",
		},

		"jumpIPProvisioningStateTest": {
			Expected:        "Succeeded",
			ActualRetriever: helpers.RetrieveFromStruct(pip, "PublicIPAddressPropertiesFormat", "ProvisioningState"),
			Message:         "Jump VM public IP provisioning state is not Succeeded",
		},

		"jumpIPNameTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, jumpIPResourceMapName, "{$.name}"),
			ActualRetriever:   helpers.RetrieveFromStruct(pip, "Name"),
			Message:           "Jump VM public IP name does not match plan",
		},

		"jumpIPAllocationMethodTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, jumpIPResourceMapName, "{$.allocation_method}"),
			ActualRetriever:   helpers.RetrieveFromStruct(pip, "PublicIPAddressPropertiesFormat", "PublicIPAllocationMethod"),
			Message:           "Jump VM public IP allocation method does not match plan",
		},
	}

	helpers.RunApplyTests(t, tests)

	t.Run("jumpIPAddressAssignedTest", func(t *testing.T) {
		ip := helpers.RetrieveFromStruct(pip, "PublicIPAddressPropertiesFormat", "IPAddress")()
		assert.NotEqual(t, "nil", ip, "Jump VM public IP address is nil")
		assert.NotEmpty(t, ip, "Jump VM public IP address is empty")
	})

	// nfs VM public IP should not exist; create_nfs_public_ip = false by default
	t.Run("nfsIPDoesNotExistTest", func(t *testing.T) {
		nfsVmName := helpers.RetrieveFromPlan(plan, "module.nfs[0].azurerm_linux_virtual_machine.vm", "{$.name}")()
		// VM name is "{prefix}-nfs-vm"; module var.name is "{prefix}-nfs"; IP name is "{prefix}-nfs-public_ip"
		nfsIPName := strings.TrimSuffix(nfsVmName, "-vm") + "-public_ip"
		exists, err := azure.PublicAddressExistsE(nfsIPName, resourceGroupName, subscriptionID)
		if err != nil {
			t.Errorf("Error checking NFS public IP existence: %s\n", err)
			return
		}
		assert.False(t, exists, "NFS VM public IP should not exist (create_nfs_public_ip=false)")
	})
}
