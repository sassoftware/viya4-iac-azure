package defaultplan

import (
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
)

// Test the Outputs section when using the sample-input-defaults.tfvars file.
func TestPlanOutputs(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"outputsLocation": {
			Expected:        "eastus",
			Retriever:       helpers.RetrieveFromRawPlan,
			ResourceMapName: "location",
			Message:         "Location should be set to eastus",
		},
		"outputsClusterApiMode": {
			Expected:        "public",
			Retriever:       helpers.RetrieveFromRawPlan,
			ResourceMapName: "cluster_api_mode",
			Message:         "Cluster API mode should be set to public",
		},
		"outputsJumpRwxFilestorePath": {
			Expected:        "/viya-share",
			Retriever:       helpers.RetrieveFromRawPlan,
			ResourceMapName: "jump_rwx_filestore_path",
			Message:         "Jump VM RWX Filestore Path should be set to /viya-share",
		},
		"outputsPrefix": {
			Expected:        "default",
			Retriever:       helpers.RetrieveFromRawPlan,
			ResourceMapName: "prefix",
			AssertFunction:  assert.Contains,
			Message:         "Prefix should contain default",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
