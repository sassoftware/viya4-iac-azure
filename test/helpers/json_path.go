// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"bytes"
	tfjson "github.com/hashicorp/terraform-json"
	"k8s.io/client-go/util/jsonpath"
)

// GetJsonPathFromStateResource retrieves the value of a jsonpath query on a given *tfjson.StateResource
// map is visited in random order
func GetJsonPathFromStateResource(resource *tfjson.StateResource, jsonPath string) (string, error) {
	return getJsonPath(resource.AttributeValues, jsonPath)
}

// GetJsonPathFromPlannedVariablesMap retrieves the value of a jsonpath query on a given *tfjson.PlanVariable
// map is visited in random order
func GetJsonPathFromPlannedVariablesMap(resourceMap *tfjson.PlanVariable, jsonPath string) (string, error) {
	return getJsonPath(resourceMap, jsonPath)
}

func getJsonPath(resource interface{}, jsonPath string) (string, error) {
	j := jsonpath.New("PlanParser")
	j.AllowMissingKeys(true)
	err := j.Parse(jsonPath)
	if err != nil {
		return "", err
	}
	buf := new(bytes.Buffer)
	err = j.Execute(buf, resource)
	if err != nil {
		return "", err
	}
	out := buf.String()
	return out, nil
}
