// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultapply

import (
	"os"
	"test/helpers"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testApplyNetwork(t *testing.T, plan *terraform.PlanStruct) {
	vnetResourceMapName := "module.vnet.azurerm_virtual_network.vnet[0]"
	vnetName := helpers.RetrieveFromPlan(plan, vnetResourceMapName, "{$.name}")()
	resourceGroupName := helpers.RetrieveFromPlan(plan, "azurerm_resource_group.aks_rg[0]", "{$.name}")()

	vnet, err := azure.GetVirtualNetworkE(vnetName, resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error getting VNet: %s\n", err)
		return
	}

	tests := map[string]helpers.ApplyTestCase{
		"vnetExistsTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(vnet, "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "VNet ID is nil",
		},
		"vnetNameTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, vnetResourceMapName, "{$.name}"),
			ActualRetriever:   helpers.RetrieveFromStruct(vnet, "Name"),
			Message:           "VNet name does not match plan",
		},
	}

	helpers.RunApplyTests(t, tests)

	// AddressPrefixes is a []string inside a nested struct; RetrieveFromStruct only returns
	// "not nil"/"nil" for slices, so we check the actual CIDR value directly.
	t.Run("vnetAddressSpaceTest", func(t *testing.T) {
		expectedSpace := helpers.RetrieveFromPlan(plan, vnetResourceMapName, "{$.address_space[0]}")()
		if vnet.AddressSpace == nil || vnet.AddressSpace.AddressPrefixes == nil || len(*vnet.AddressSpace.AddressPrefixes) == 0 {
			t.Error("VNet address space is nil or empty")
			return
		}
		assert.Equal(t, expectedSpace, (*vnet.AddressSpace.AddressPrefixes)[0], "VNet address space does not match plan")
	})
}
