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

func testApplyResourceGroup(t *testing.T, plan *terraform.PlanStruct) {
	resourceMapName := "azurerm_resource_group.aks_rg[0]"
	resourceGroupName := helpers.RetrieveFromPlan(plan, resourceMapName, "{$.name}")()
	resourceGroup, err := azure.GetAResourceGroupE(resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}

	// validate resource group resource from the cloud provider match the plan
	tests := map[string]helpers.ApplyTestCase{
		"resourceGroupExistsTest": {
			Expected:       nil,
			Actual:         resourceGroup,
			AssertFunction: assert.NotEqual,
			Message:        "Resource group does not exist",
		},
		"resourceGroupLocationTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, resourceMapName, "{$.location}"),
			ActualRetriever:   helpers.RetrieveFromStruct(resourceGroup, "Location"),
			Message:           "Resource group location is incorrect",
		},
		"resourceGroupNameTest": {
			Expected:        resourceGroupName,
			ActualRetriever: helpers.RetrieveFromStruct(resourceGroup, "Name"),
			Message:         "Resource group name is incorrect",
		},
		"resourceGroupIdTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(resourceGroup, "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "Resource group ID is nil",
		},
	}

	helpers.RunApplyTests(t, tests)
}
