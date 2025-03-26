// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

var lock = &sync.Mutex{}
var CACHE *PlanCache

type PlanCache struct {
	plans map[string]*terraform.PlanStruct
	lock  sync.Mutex
}

func getCache() *PlanCache {
	if CACHE == nil {
		lock.Lock()
		defer lock.Unlock()
		if CACHE == nil {
			CACHE = &PlanCache{
				plans: make(map[string]*terraform.PlanStruct),
			}
		}
	}
	return CACHE
}

// Not worrying about expiration since this is for a single run of tests.
func (c *PlanCache) get(key string, planFn func() *terraform.PlanStruct) *terraform.PlanStruct {
	c.lock.Lock()
	defer c.lock.Unlock()

	plan, ok := c.plans[key]
	if !ok {
		c.plans[key] = planFn()
		return c.plans[key]
	}
	return plan
}

func GetDefaultPlan(t *testing.T) *terraform.PlanStruct {
	return GetPlanFromCache(t, GetDefaultPlanVars(t))
}

func GetPlanFromCache(t *testing.T, variables map[string]interface{}) *terraform.PlanStruct {
	return getCache().get(variables["prefix"].(string), func() *terraform.PlanStruct {
		return GetPlan(t, variables)
	})
}

func GetPlan(t *testing.T, variables map[string]interface{}) *terraform.PlanStruct {
	plan, err := InitPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)
	return plan
}

// InitPlanWithVariables returns a *terraform.PlanStruct
func InitPlanWithVariables(t *testing.T, variables map[string]interface{}) (*terraform.PlanStruct, error) {
	// Create a temporary plan file
	planFileName := "testplan-" + variables["prefix"].(string) + ".tfplan"
	planFilePath := filepath.Join(os.TempDir(), planFileName)
	defer os.Remove(planFilePath)

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../../", "")
	// Get the path to the parent folder for clean up
	tempTestFolderSlice := strings.Split(tempTestFolder, string(os.PathSeparator))
	tempTestFolderPath := strings.Join(tempTestFolderSlice[:len(tempTestFolderSlice)-1], string(os.PathSeparator))
	defer os.RemoveAll(tempTestFolderPath)

	// Set up Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         variables,
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	return terraform.InitAndPlanAndShowWithStructE(t, terraformOptions)
}

// GetDefaultPlanVars returns a map of default terratest variables
func GetDefaultPlanVars(t *testing.T) map[string]interface{} {
	tfVarsPath := "../../examples/sample-input-defaults.tfvars"

	variables := make(map[string]interface{})
	err := terraform.GetAllVariablesFromVarFileE(t, tfVarsPath, &variables)
	assert.NoError(t, err)

	variables["prefix"] = "default"
	variables["location"] = "eastus"
	variables["default_public_access_cidrs"] = []string{"123.45.67.89/16"}

	return variables
}
