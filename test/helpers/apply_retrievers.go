package helpers

import (
	"github.com/Azure/azure-sdk-for-go/services/compute/mgmt/2019-07-01/compute"
	"github.com/Azure/azure-sdk-for-go/services/resources/mgmt/2020-10-01/resources"
	"github.com/gruntwork-io/terratest/modules/azure"
	"os"
	"reflect"
)

func RetrieveGroupExists(variables map[string]interface{}) (function func() string) {
	return func() string {
		exists, err := azure.ResourceGroupExistsE(variables["resourceGroupName"].(string), os.Getenv("TF_VAR_subscription_id"))
		if err == nil && exists {
			return "true"
		}
		return "false"
	}
}

func RetrieveFromGroup(resourceGroup *resources.Group, fieldName string) (function func() string) {
	return RetrieveFromStruct(resourceGroup, fieldName)
}

func RetrieveFromVirtualMachine(virtualMachine *compute.VirtualMachine, fieldName string) (function func() string) {
	return RetrieveFromStruct(virtualMachine, fieldName)
}

func RetrieveVMExists(variables map[string]interface{}, vmName string) (function func() string) {
	return func() string {
		exists, err := azure.VirtualMachineExistsE(vmName, variables["resourceGroupName"].(string), os.Getenv("TF_VAR_subscription_id"))
		if err == nil && exists {
			return "true"
		}
		return "false"
	}
}

func RetrieveFromStruct(input interface{}, fieldName string) func() string {
	return func() string {
		if input == nil {
			return "nil"
		}

		val := reflect.ValueOf(input)
		if val.Kind() == reflect.Ptr {
			val = reflect.Indirect(val)
		}

		if val.Kind() != reflect.Struct {
			return "nil"
		}

		field := val.FieldByName(fieldName)
		if !field.IsValid() || field.Kind() != reflect.String {
			return "nil"
		}

		return field.String()
	}
}
