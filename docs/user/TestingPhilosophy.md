# Testing Philosophy

## Introduction
Our testing philosophy centers around ensuring the highest quality of infrastructure code through rigorous and systematic testing practices. We believe that thorough testing is essential to delivering a reliable and maintainable infrastructure solution. In order to achieve this level of quality, we have set up a testing framework to run automated unit and integration tests. These tests are integrated into our CI/CD process. Because this project is community-driven, we require both internal and external contributions to be accompanied by unit and/or integration tests, as stated in our [CONTRIBUTING.md](../../CONTRIBUTING.md) document. This ensures that new changes do not break existing functionality.

## Testing Approach

This project uses the [Terratest](https://terratest.gruntwork.io/) Go library to verify the stability and quality of our infrastructure code. The tests fall into two categories: unit tests and integration tests.

### Unit Testing

The unit tests in this project are designed to quickly and efficiently verify the code base without provisioning any resources or incurring any resource costs. We avoid provisioning resources by using Terraform's plan files. Because the unit tests are integrated into the SAS CI/CD process, they need to run as often as possible.

### Unit Testing Structure

The unit tests are written as [table-driven tests](https://go.dev/wiki/TableDrivenTests) so that they are easier to read, understand, and expand. The tests are divided into two files, [default_unit_test.go](../../test/default_unit_test.go) and [non_default_unit_test.go](../../test/non_default_unit_test.go).

The test file named default_unit_test.go validates the default values of a Terraform plan. This testing ensures that there are no regressions in the default behavior of the code base. The test file named non_default_unit_test.go modifies the input values before running the Terraform plan. After generating the plan file, the test verifies that it contains the expected values. Both files are written as table-driven tests.

To see an example, look at the `TestPlanStorageDefaults` function in the default_unit_test.go file that is shown below.

With the Table-Driven approach, each entry in the `storageTests` map is a test. These tests verify that the expected value matches the actual value of the "module.nfs[0].azurerm_linux_virtual_machine.vm" resource.  We use the [k8s.io JsonPath](https://pkg.go.dev/k8s.io/client-go@v0.28.4/util/jsonpath) library to parse the Terraform output and extract the desired attribute.  The runTest call is a helper function that runs through each test in the map and perform assertions. See the [helpers.go](../../test/helpers.go) file for more information on the common helper functions.

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

To create a unit test, you can add an entry to an existing test table in the [default_unit_test.go](../../test/default_unit_test.go) file or the [non_default_unit_test.go](../../test/non_default_unit_test.go) file, depending on the test type. If you don't see an existing test table that fits your needs, you are welcome to create a new function in a similar table-driven test format.

### Integration Testing

The integration tests are designed to thoroughly verify the code base using `terraform apply`. Unlike the unit tests, these tests provision resources in cloud platforms. Careful consideration is required to avoid unnecessary infrastructure costs.

These test are still a work-in-progress. We will update these sections once we have more examples to reference.

### Integration Testing Structure

These test are still a work-in-progress. We will update these sections once we have more examples to reference.

## How to Run the Tests Locally

Before changes can be merged, all unit tests must pass as part of the SAS CI/CD process. Unit tests are automatically run against every PR using the [Dockerfile.terratest](../../Dockerfile.terratest) Docker image. Refer to [TerratestDockerUsage.md](./TerratestDockerUsage.md) document for more information about running the tests locally.


## Additional Documents

* [Go Table-Driven Testing](https://go.dev/wiki/TableDrivenTests)
* [Terratest Documentation](https://terratest.gruntwork.io/docs/)