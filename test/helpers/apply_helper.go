// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	tfjson "github.com/hashicorp/terraform-json"
	"github.com/stretchr/testify/require"
)

// ExistingStateEnvVar, when set to the path of a terraform.tfstate file, makes the apply
// tests validate that already-deployed infrastructure instead of creating and destroying it.
const ExistingStateEnvVar = "TERRATEST_EXISTING_TFSTATE"

func InitPlanAndApply(t *testing.T, overrides map[string]interface{}) (*terraform.Options, *terraform.PlanStruct) {
	if statePath := os.Getenv(ExistingStateEnvVar); statePath != "" {
		validateEnvVars(t, "TF_VAR_client_id", "TF_VAR_client_secret", "TF_VAR_tenant_id", "TF_VAR_subscription_id")
		t.Logf("%s is set; testing existing deployment from %s (no apply/destroy)", ExistingStateEnvVar, statePath)
		return nil, LoadPlanFromState(t, statePath)
	}

	validateEnvVars(t, "TF_VAR_client_id", "TF_VAR_client_secret", "TF_VAR_tenant_id",
		"TF_VAR_subscription_id", "TF_VAR_public_cidrs")

	tfVarsPath := "../../examples/sample-input-defaults.tfvars"

	variables := make(map[string]interface{})
	terraform.GetAllVariablesFromVarFile(t, tfVarsPath, &variables)

	// Use a unique prefix in case multiple applies are processing.
	variables["prefix"] = "terratest-" + strings.ToLower(random.UniqueId())
	variables["location"] = "eastus"
	variables["default_public_access_cidrs"] = os.Getenv("TF_VAR_public_cidrs")
	if overrides != nil {
		for k, v := range overrides {
			variables[k] = v
		}
	}

	// Set up Terraform options with temporary folders (deleted in DestroyDouble)
	options := &terraform.Options{
		TerraformDir: test_structure.CopyTerraformFolderToTemp(t, "../../", ""),
		Vars:         variables,
		PlanFilePath: filepath.Join(os.TempDir(), "testplan-"+variables["prefix"].(string)+".tfplan"),
		NoColor:      true,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, options)

	terraform.Apply(t, options)

	return options, plan
}

// LoadPlanFromState builds a PlanStruct whose ResourcePlannedValuesMap is populated from an
// existing terraform.tfstate, so the apply tests can compare live Azure resources against it.
func LoadPlanFromState(t *testing.T, statePath string) *terraform.PlanStruct {
	data, err := os.ReadFile(statePath)
	require.NoError(t, err, "Unable to read terraform state file %s", statePath)

	var state struct {
		Resources []struct {
			Module    string `json:"module"`
			Mode      string `json:"mode"`
			Type      string `json:"type"`
			Name      string `json:"name"`
			Instances []struct {
				IndexKey   interface{}            `json:"index_key"`
				Attributes map[string]interface{} `json:"attributes"`
			} `json:"instances"`
		} `json:"resources"`
	}
	require.NoError(t, json.Unmarshal(data, &state), "Unable to parse terraform state file %s", statePath)

	resources := make(map[string]*tfjson.StateResource)
	for _, r := range state.Resources {
		address := r.Type + "." + r.Name
		if r.Mode == "data" {
			address = "data." + address
		}
		if r.Module != "" {
			address = r.Module + "." + address
		}
		for _, instance := range r.Instances {
			instanceAddress := address
			switch key := instance.IndexKey.(type) {
			case float64:
				instanceAddress += fmt.Sprintf("[%d]", int(key))
			case string:
				instanceAddress += fmt.Sprintf("[%q]", key)
			}
			resources[instanceAddress] = &tfjson.StateResource{
				Address:         instanceAddress,
				Type:            r.Type,
				Name:            r.Name,
				Index:           instance.IndexKey,
				AttributeValues: instance.Attributes,
			}
		}
	}
	require.NotEmpty(t, resources, "No resources found in terraform state file %s", statePath)

	return &terraform.PlanStruct{ResourcePlannedValuesMap: resources}
}

func validateEnvVars(t *testing.T, vars ...string) {
	for _, v := range vars {
		if os.Getenv(v) == "" {
			t.Fatalf("Environment variable %s must be set", v)
		}
	}
}

func DestroyDouble(t *testing.T, terraformOptions *terraform.Options) {
	// Existing deployment mode: infrastructure is not owned by the test, never destroy it
	if terraformOptions == nil {
		t.Log("Existing deployment mode; skipping destroy")
		return
	}

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
