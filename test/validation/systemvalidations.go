/*
 * Copyright (c) 2020-2022, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
 */

// Package validation ...
package validation

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// SystemValidations are the definitions for validating the result of
// an orchestration command execution.
type SystemValidations struct {
	// Args are the command line arguments to issue.
	Args []string

	Plan *terraform.PlanStruct

	// ExecutionError indicates the validations to run against
	// the golang error returned by the command execution. For
	// successful runs, the recommended check is either
	// assert.NoError or require.NoError.
	ExecutionError ErrorValidations

	// Stdout indicates the validations to run against stdout.
	Stdout Validations

	// Stderr indicates the validations to run against stderr.
	Stderr Validations

	// Files maps file paths to the validations that should be run
	// against the file contents. If Args has --output defined,
	// relative paths will be resolved against the --output directory.
	// If --output is set to "-", file validations are run against the
	// exploded tar archive contents.
	Files map[string]Validations

	// Globs maps file globs to the validations that should be run against the
	// file contents for all matching files. If Args has --output defined,
	// relative paths will be resolved against the --output directory. If
	// --output is set to "-", file validations are run against the exploded tar
	// archive contents.
	Globs map[string]Validations

	// Filesystem maps file paths to the validations that should be
	// run against the given path. If Args has --output defined,
	// relative paths will be resolved against the --output directory.
	// If --output is set to "-", filesystem validations are run
	// against the exploded tar archive contents.
	Filesystem map[string]Validations

	// PreExecute is an array of functions to call, in order, after
	// test setup but prior to the command execution.
	PreExecute []func()
}

func pathExists(path string) (bool, error) {
	_, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false, nil
	}
	if err == nil {
		return true, nil
	}
	// Indeterminate state
	return false, err
}

// Execute runs the test.
func (sv *SystemValidations) Execute(t *testing.T) {
	cluster := sv.Plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]
	assert.NotNil(t, cluster)
	// vnet_address_space
	expectedVnetAddress := []interface{}{"192.168.0.0/16"}
	vnetResource := sv.Plan.ResourcePlannedValuesMap["module.vnet.azurerm_virtual_network.vnet[0]"]
	vnetAttributes := vnetResource.AttributeValues["address_space"].([]interface{})
	assert.Equal(t, expectedVnetAddress, vnetAttributes)
}

func (sv *SystemValidations) runFsChecks(t *testing.T, stdout string) {
	//outputDir := sv.getOutputDir()
	//context := ""
	//isTar := outputDir == constants.StdOutOutputValue
	//if isTar {
	//	// Create a memory map filesystem for tar expansion.
	//	memMapFs := filesystem.NewWorkingFs()
	//	common.TarToFs(t, stdout, memMapFs)
	//
	//	// Temporarily make it the output filesystem, so that
	//	// fsassert checks will work as expected.
	//	filesystem.ApplyOutputFsOverride(memMapFs)
	//	defer filesystem.RemoveOutputFsOverride()
	//
	//	context = "tar "
	//}
	//
	//fs := filesystem.GetOutputFs()
	//
	//validateFileFn := func(filepath string, validations Validations) {
	//	bytes, err := afero.ReadFile(fs, filepath)
	//	require.NoError(t, err)
	//	asString := string(bytes)
	//	validations.Execute(t, asString, "Context ("+context+"file content): "+filepath)
	//}
	//
	//for path, validations := range sv.Files {
	//	aferoFile := getPathReference(t, path, outputDir, isTar)
	//	validateFileFn(aferoFile, validations)
	//}
	//
	//for path, validations := range sv.Globs {
	//	aferoGlob := getPathReference(t, path, outputDir, isTar)
	//	aferoFiles, err := afero.Glob(fs, aferoGlob)
	//	require.NoError(t, err)
	//	for _, aferoFile := range aferoFiles {
	//		validateFileFn(aferoFile, validations)
	//	}
	//}
	//
	//for path, validations := range sv.Filesystem {
	//	aferoFile := getPathReference(t, path, outputDir, isTar)
	//	validations.Execute(t, aferoFile, "Context ("+context+"filesystem): "+aferoFile)
	//}
}

func getPathReference(t *testing.T, path string, outputDir string, isTar bool) string {
	if isTar {
		return filepath.ToSlash(path)
	}
	if outputDir != "" && !filepath.IsAbs(path) {
		path = filepath.Join(outputDir, path)
	}
	aferoFile, err := filepath.Abs(path)
	require.NoError(t, err)
	return aferoFile
}

func (sv *SystemValidations) getOutputDir() string {
	slot := 0
	for i := len(sv.Args) - 1; i >= 0; i-- {
		if sv.Args[i] == "--output" {
			slot = i + 1
			break
		}
	}
	if slot < len(sv.Args) {
		return sv.Args[slot]
	}
	return ""
}
