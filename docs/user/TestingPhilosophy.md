# Testing Philosophy

## Introduction
Our testing philosophy centers around ensuring the highest quality of infrastructure code through rigorous and systematic testing practices. We believe that thorough testing is essential to delivering a reliable and maintainable infrastructure solution.  In order to achieve this, we have set up a testing framework to run unit and integration tests. These tests are integrated into our CI/CD process. Because this project is community driven, we require both internal and external contributions to be accompanied by unit and/or integration tests as stated in our [CONTRIBUTING.md](../../CONTRIBUTING.md) document. This ensures that new changes do not break existing functionality.

## Testing Approach

This project leverages the Go library [Terratest](https://terratest.gruntwork.io/) to verify the stability and quality of our infrastructure code. The tests can be broken down into two categories: unit tests and integration tests. 

### Unit Testing

The unit tests are designed to quickly and efficiently verify the codebase without provisioning any resources. We do this by using Terraform's plan files. Because the unit tests are integrated into our CI/CD process, they should not create any resources. We want to run them as often as possible, so they should not incur any costs.

### Unit Testing Structure

The unit tests are written as [Table-Driven tests](https://go.dev/wiki/TableDrivenTests) so they are easier to read, understand, and expand. The tests are be broken up into two files, [default_unit_test.go](../../test/default_unit_test.go) and [non_default_unit_test.go](../../test/non_default_unit_test.go).

`default_unit_test.go` validates the default values of a terraform plan. This ensures that there are no regressions in the default behavior. `non_default_unit_test.go` modifies the input values before running the `terraform plan`. After generating the plan file, the test verifies that it contains the expected values. Both files are written as Table-Driven tests. Each resource type has an associated Test function.

For example, look at the `TestPlanStorageDefaults` function in `default_unit_test.go` (copied below).

With the Table-Driven approach, each entry in the `storageTests` map is a test. These tests verify that the expected value matches the actual value of the "module.nfs[0].azurerm_linux_virtual_machine.vm" resource.  We use the [k8s.io JsonPath](https://pkg.go.dev/k8s.io/client-go@v0.28.4/util/jsonpath) library to parse the terraform output and extract the desired attribute.  The runTest call is a helper function that runs through each test in the map and perform assertions. See the [helpers.go](../../test/helpers.go) for more information on the common helper functions.

```go
// Function containing all unit tests for the Storage type
// and its default values.
func TestPlanStorageDefaults(t *testing.T) {
    // Map containing the different tests. Each entry is 
    // a separate test.
    storageTests := map[string]testCase{
        // Verify that the default user is 'nfsuser'.
        "userTest": {
            expected:          "nfsuser",
            resourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
            attributeJsonPath: "{$.admin_username}",
        },
        // Verify that the default size is 'Standard_D4s_v5'.
        "sizeTest": {
            expected:          "Standard_D4s_v5",
            resourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
            attributeJsonPath: "{$.size}",
        },
    }

    // Generate a Plan file using the default input variables.
    variables := getDefaultPlanVars(t)
    plan, err := initPlanWithVariables(t, variables)
    require.NotNil(t, plan)
    require.NoError(t, err)
    
    // For each test in the Test Table, run the test helper function
    for name, tc := range storageTests {
        t.Run(name, func(t *testing.T) {
            runTest(t, tc, plan)
        })
    }
}
```
### Adding Unit Tests

To create a unit test, you can add an entry to an existing test table in the [default_unit_test.go](../../test/default_unit_test.go) or [non_default_unit_test.go](../../test/non_default_unit_test.go), depending on the test type. If there isn't an existing test table that fits your needs, you are welcome to create a new function in a similar Table-Driven test format.

### Integration Testing

The integration tests are designed to thoroughly verify the codebase using `terraform apply`. These tests provision resources in the cloud platforms, so careful consideration will be needed to avoid unnecessary costs.

These test are still a work-in-progress. We will update these sections once we have more examples to reference.

### Integration Testing Structure

These test are still a work-in-progress. We will update these sections once we have more examples to reference.

## How to run the tests locally

Before changes can be merged, we require all unit tests to pass as part of our CI/CD process. Unit tests are automatically run against every PR using the [Dockerfile.terratest](../../Dockerfile.terratest) Docker image. Please refer to [TerratestDockerUsage.md](./TerratestDockerUsage.md) document for more information regarding locally running the tests.


## Additional Documents

* [Go Table-Driven Testing](https://go.dev/wiki/TableDrivenTests)
* [Terratest Documentation](https://terratest.gruntwork.io/docs/)