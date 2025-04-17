package defaultapply

import (
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"os"
	"test/helpers"
	"testing"
)

func testApplyResourceGroup(t *testing.T, plan *terraform.PlanStruct) {
	resourceMapName := "azurerm_resource_group.aks_rg[0]"
	resourceGroupName := helpers.RetrieveFromPlan(plan, resourceMapName, "name")()
	resourceGroup := azure.GetAResourceGroup(t, resourceGroupName, os.Getenv("TF_VAR_subscription_id"))

	tests := map[string]helpers.ApplyTestCase{
		"resourceGroupExistsTest": {
			Expected:        "true",
			ActualRetriever: helpers.RetrieveGroupExists(resourceGroupName),
			Message:         "Resource group does not exist",
		},
		"resourceGroupLocationTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, resourceMapName, "{$.location}"),
			ActualRetriever:   helpers.RetrieveFromGroup(resourceGroup, "Location"),
			Message:           "Resource group location is incorrect",
		},
		"resourceGroupNameTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, resourceMapName, "{$.name}"),
			ActualRetriever:   helpers.RetrieveFromGroup(resourceGroup, "Name"),
			Message:           "Resource group name is incorrect",
		},
		"resourceGroupIdTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromGroup(resourceGroup, "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "Resource group ID is nil",
		},
	}

	helpers.RunApplyTests(t, tests)
}
