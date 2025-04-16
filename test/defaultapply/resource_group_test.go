package defaultapply

import (
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/stretchr/testify/assert"
	"os"
	"test/helpers"
	"testing"
)

func testApplyResourceGroup(t *testing.T, variables map[string]interface{}) {
	// Get the resource group attributes and check if they are correct
	resourceGroup := azure.GetAResourceGroup(t, variables["resourceGroupName"].(string), os.Getenv("TF_VAR_subscription_id"))

	tests := map[string]helpers.ApplyTestCase{
		"resourceGroupExistsTest": {
			Expected:  "true",
			Retriever: helpers.RetrieveGroupExists(variables),
			Message:   "Resource group does not exist",
		},
		"resourceGroupLocationTest": {
			Expected:  variables["resourceGroupLocation"].(string),
			Retriever: helpers.RetrieveFromGroup(resourceGroup, "Location"),
			Message:   "Resource group location is incorrect",
		},
		"resourceGroupNameTest": {
			Expected:  variables["resourceGroupName"].(string),
			Retriever: helpers.RetrieveFromGroup(resourceGroup, "Name"),
			Message:   "Resource group name is incorrect",
		},
		"resourceGroupIdTest": {
			Expected:       "nil",
			Retriever:      helpers.RetrieveFromGroup(resourceGroup, "ID"),
			AssertFunction: assert.NotEqual,
			Message:        "Resource group ID is nil",
		},
	}

	helpers.RunApplyTests(t, tests)
}
