// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

func InitAndApply(t *testing.T) (*terraform.Options, *terraform.PlanStruct) {
	validateEnvVars(t, "TF_VAR_client_id", "TF_VAR_client_secret", "TF_VAR_tenant_id",
		"TF_VAR_subscription_id", "TF_VAR_public_cidrs")

	tfVarsPath := "../../examples/sample-input-defaults.tfvars"

	variables := make(map[string]interface{})
	terraform.GetAllVariablesFromVarFile(t, tfVarsPath, &variables)

	// Use a unique prefix in case multiple applies are processing.
	variables["prefix"] = "terratest" + strings.ToLower(random.UniqueId())
	variables["location"] = "eastus"
	variables["default_public_access_cidrs"] = os.Getenv("TF_VAR_public_cidrs")

	// Set up Terraform options with temporary folders (deleted in DestroyDouble)
	options := &terraform.Options{
		TerraformDir: test_structure.CopyTerraformFolderToTemp(t, "../../", ""),
		Vars:         variables,
		PlanFilePath: filepath.Join(os.TempDir(), "testplan-"+variables["prefix"].(string)+".tfplan"),
		NoColor:      true,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, options)

	terraform.InitAndApply(t, options)

	return options, plan
}

func validateEnvVars(t *testing.T, vars ...string) {
	for _, v := range vars {
		if os.Getenv(v) == "" {
			t.Fatalf("Environment variable %s must be set", v)
		}
	}
}

func DestroyDouble(t *testing.T, terraformOptions *terraform.Options) {
	// Destroy the resources we created
	_, err := terraform.DestroyE(t, terraformOptions)
	if err != nil {
		// If the first destroy fails, try to destroy again
		_, out := terraform.DestroyE(t, terraformOptions)
		// If the second destroy fails, fail the test for further investigation
		if out != nil {
			require.NoError(t, out)
		}
	}

	// Remove the temporary folders
	err = os.Remove(terraformOptions.PlanFilePath)
	require.NoError(t, err)
	tempTestFolderSlice := strings.Split(terraformOptions.TerraformDir, string(os.PathSeparator))
	tempTestFolderPath := strings.Join(tempTestFolderSlice[:len(tempTestFolderSlice)-1], string(os.PathSeparator))
	err = os.RemoveAll(tempTestFolderPath)
	require.NoError(t, err)
}
