# Testing Philosophy

## Introduction
Our testing philosophy centers around ensuring the highest quality of infrastructure code through rigorous and systematic testing practices. We believe that thorough testing is essential to delivering a reliable and maintainable infrastructure solution. In order to achieve this level of quality, we have set up a testing framework to run automated unit and integration tests. These tests are integrated into our CI/CD process. Because this project is community-driven, we require both internal and external contributions to be accompanied by unit and/or integration tests, as stated in our [CONTRIBUTING.md](../../CONTRIBUTING.md) document. This ensures that new changes do not break existing functionality.

## Testing Approach

This project uses the [Terratest](https://terratest.gruntwork.io/) Go library to verify the stability and quality of our infrastructure code. The tests fall into two categories: unit tests and integration tests.

### Unit Testing

The unit tests in this project are designed to quickly and efficiently verify the code base without provisioning any resources or incurring any resource costs. We avoid provisioning resources by using Terraform's plan files. Because the unit tests are integrated into the SAS CI/CD process, they need to run as often as possible.

### Unit Testing Structure

The unit tests are written as [table-driven tests](https://go.dev/wiki/TableDrivenTests) so that they are easier to read, understand, and expand. The tests are divided into two packages, [defaultplan](../../test/defaultplan) and [nondefaultplan](../../test/nondefaultplan).

The test package defaultplan validates the default values of a `terraform plan`. This testing ensures that there are no regressions in the default behavior of the code base. The test package nondefaultplan modifies the input values before running the Terraform plan. After generating the plan file, the test verifies that it contains the expected values. Both sets of tests are written to be table-driven.

To see an example, look at the `TestPlanStorage` function in the defaultplan/storage_test.go file that is shown below.

With the Table-Driven approach, each entry in the `tests` map is a test. These tests verify that the expected value matches the actual value of the "module.nfs[0].azurerm_linux_virtual_machine.vm" resource.  We use the [k8s.io JsonPath](https://pkg.go.dev/k8s.io/client-go@v0.28.4/util/jsonpath) library to parse the Terraform output and extract the desired attribute.  The RunTests call is a helper function that runs through each test in the map and perform the supplied assertions. See the [helpers](../../test/helpers) package for more information on the common helper functions.

```go
func TestPlanStorage(t *testing.T) {
    t.Parallel()


    tests := map[string]helpers.TestCase{
        "userTest": {
            Expected:          "nfsuser",
            ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
            AttributeJsonPath: "{$.admin_username}",
        },
        "sizeTest": {
            Expected:          "Standard_D4s_v5",
            ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
            AttributeJsonPath: "{$.size}",
        },
        "vmNotNilTest": {
            Expected:          "<nil>",
            ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
            AttributeJsonPath: "{$}",
            AssertFunction:    assert.NotEqual,
        },
        "vmZoneEmptyStrTest": {
            Expected:          "",
            ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
            AttributeJsonPath: "{$.vm_zone}",
        },

    // Run the tests using the default input variables.
    helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
```
### Adding Unit Tests

To create a unit test, you can add an entry to an existing test table if it's related to the resources being validated. If you don't see an existing test table that fits your needs, you are welcome to create a new file in a similar table-driven test format and drop it in the appropriate package.

### Integration Testing

The integration tests are designed to thoroughly verify the code base using `terraform apply`. The tests are intended to validate that the cloud provider is going to create the resources we're telling it to create through Terraform. Unlike the unit tests, these tests provision resources through the cloud provider. Careful consideration is required to avoid unnecessary infrastructure costs. The integration test framework is designed to optimize resource utilization and reduce associated costs by enabling multiple test cases to run against a single provisioned resource, provided the test cases are compatible with the resource’s configuration and state.  Because the integration tests take more time and incur costs, they will not run as frequently as the unit tests but will still run on a regular basis.

### Integration Testing Structure

The integration tests are also written as [table-driven tests](https://go.dev/wiki/TableDrivenTests) so that they are easier to read, understand, and expand. The tests are divided into two packages, [defaultapply](../../test/defaultapply) and [nondefaultapply](../../test/nondefaultapply).

The test package defaultapply validates that the default plan values and configurations match what the cloud provider provisions. The test package nondefaultapply validates that the non default plan values and configurations match what the cloud provider provisions. This level of integration testing ensures the cloud provider is properly and correctly creating the resources we tell it to create via Terraform.

### Resource Management

As running `terraform apply` provisions infrastructure, it inherently incurs costs. To manage and minimize these expenses, it is essential that our testing framework optimizes resource utilization and ensures proper teardown and cleanup of any infrastructure created during testing.

To support this, we have implemented main function test runners for our integration tests that handle the setup of the testing environment by provisioning resources based on the provided Terraform options. These runners also include deferred cleanup routines that automatically decommission resources once tests are completed.

We encourage developers contributing integration tests to be mindful of resource usage. Add your tests to the defaultapply suite if no plan changes are needed.  If testing non default options please modify the nondefault suite as long as the new options do not conflict with the existing overrides.  Otherwise feel free to add a new non default apply package, test runner, and test suite for your unique option configuration.

To see an example, look at the test functions in [default_apply_main_test.go](../../test/defaultapply/default_apply_main_test.go) and [nondefaultapply](../../test/nondefaultapply/non_default_apply_main_test.go) that is shown below.

```go
func TestApplyDefaultMain(t *testing.T) {
	// terraform init and apply using a default plan
	terraformOptions, plan := helpers.InitAndApply(t, nil)

	// deferred cleanup routine for the resources created by the terraform init and apply after the test have been run
	defer helpers.DestroyDouble(t, terraformOptions)

	// Drop in new test cases here
	testApplyResourceGroup(t, plan)
	testApplyVirtualMachine(t, plan)
}
```

```go
func TestApplyNonDefaultMain(t *testing.T) {
	// terraform init and apply using non-default values
	overrides := make(map[string]interface{})
	overrides["kubernetes_version"] = "1.32.0"
	overrides["create_container_registry"] = true
	overrides["container_registry_admin_enabled"] = true
	overrides["container_registry_geo_replica_locs"] = []string{"southeastus5", "southeastus3"}
	overrides["rbac_aad_enabled"] = true
	overrides["storage_type"] = "ha"

	// deferred cleanup routine for the resources created by the terraform init and apply after the test have been run
	terraformOptions, _ := helpers.InitAndApply(t, overrides)

	defer helpers.DestroyDouble(t, terraformOptions)

	// Drop in test cases here

}
}
```

### Error Handling

Terratest provides some flexibility with how to [handle errors](https://terratest.gruntwork.io/docs/testing-best-practices/error-handling/) Every method in Terratest comes in two versions (e.g., `terraform.Apply` and `terraform.ApplyE` )

* `terraform.Apply`: The base method takes a `t *testing.T` as an argument. If the method hits any errors, it calls `t.Fatal` to fail the test
* `terraform.ApplyE`: Methods that end with the capital letter `E` always return an error as the last argument and never call `t.Fatal` themselves. This allows you to decide how to handle errors.

We recommend using the capital letter `E` version of Terratest methods because `t.Fatal` will immediately exit the test run and prevent our other tests that have yet to be run from running and deferred cleanup routine from being executed which would result in incomplete test runs and unexpected extra costs. This is because `t.Fatal` ultimately calls `os.Exit(1)`, which immediately terminates the program

Here's an example of how we handle terratest method calls:

```go
resourceGroup, err := azure.GetAResourceGroupE(resourceGroupName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error: %s\n", err)
	}
}
```

### Adding Integration Tests

To create an integration test, you can add a new test file with your table tests to the appropriate package and update the desired main function test runner to call and run your test.  If you don't see a main function test runner that fits your needs, you are welcome to create a new package, main function test runner, and test suite in a similar format.

Below is an example of a possible structure for the new package, main function test runner, and test suite:

    .
    └── test/
        └── nondefaultapply/
            └── nondefaultapplycustomconfig/
                ├── non_default_apply_custom_config_main_test.go
                └── test_custom_config.go


## How to Run the Tests Locally

Before changes can be merged, all unit tests must pass as part of the SAS CI/CD process. Unit tests are automatically run against every PR using the [Dockerfile.terratest](../../Dockerfile.terratest) Docker image. Refer to [TerratestDockerUsage.md](./TerratestDockerUsage.md) document for more information about running the tests locally.

## Additional Documents

* [Go Table-Driven Testing](https://go.dev/wiki/TableDrivenTests)
* [Terratest Documentation](https://terratest.gruntwork.io/docs/)