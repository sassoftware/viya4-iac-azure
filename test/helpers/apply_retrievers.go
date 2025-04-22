// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"fmt"
	"reflect"

	"github.com/Azure/azure-sdk-for-go/services/compute/mgmt/2019-07-01/compute"
	"github.com/Azure/azure-sdk-for-go/services/resources/mgmt/2020-10-01/resources"
)

func RetrieveFromGroup(resourceGroup *resources.Group, fieldNames ...string) (function func() string) {
	return RetrieveFromStruct(resourceGroup, fieldNames)
}

func RetrieveFromVirtualMachine(virtualMachine *compute.VirtualMachine, fieldNames ...string) (function func() string) {
	return RetrieveFromStruct(virtualMachine, fieldNames)
}

func RetrieveFromStruct(input interface{}, fieldNames []string) func() string {
	return func() string {
		if len(fieldNames) == 0 {
			return "nil"
		}

		value := reflect.ValueOf(input)

		for _, fieldName := range fieldNames {
			// Ensure the value is a struct or pointer to a struct
			if value.Kind() == reflect.Ptr {
				value = value.Elem()
			}
			if value.Kind() != reflect.Struct {
				return "nil"
			}

			// Get the field by name
			value = value.FieldByName(fieldName)
			if !value.IsValid() {
				return "nil"
			}
		}

		// Do a final dereference if necessary
		if value.Kind() == reflect.Ptr {
			value = value.Elem()
		}
		kind := value.Kind()

		switch kind {
		case reflect.String:
			return value.String()
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
			return fmt.Sprintf("%d", value.Int())
		case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
			return fmt.Sprintf("%d", value.Uint())
		case reflect.Float32, reflect.Float64:
			return fmt.Sprintf("%f", value.Float())
		case reflect.Bool:
			return fmt.Sprintf("%t", value.Bool())
		case reflect.Slice:
			if value.Len() > 0 {
				return "not nil"
			}
			return "nil"
		default:
			return "nil"
		}
	}
}
