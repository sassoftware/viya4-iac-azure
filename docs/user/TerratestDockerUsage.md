# Using the Terratest Docker Container

Use the Terratest Docker container to run the suite of Terratest Go tests. For more information on Terratest, follow the [Documentation](https://terratest.gruntwork.io/docs/) page. The Terratest Docker image is used by the [Github Workflow](../../.github/workflows/default_plan_unit_tests.yml) as a required check before merging changes.

## Prereqs

- Docker [installed on your workstation](../../README.md#docker).

## Preparation

### Docker image

Run the following command to create the `viya4-iac-azure-terratest` Docker image using the provided [Dockerfile.terratest](../../Dockerfile.terratest)

```bash
docker build -t viya4-iac-azure-terratest -f Dockerfile.terratest .
```

The Docker image `viya4-iac-azure-terratest` will contain Terraform and Go executables, as well as the required Go modules. The Docker entrypoint for the image is `go test`, and it accepts several optional command-line arguments. For more information about command-line arguments, see [Command-Line Arguments](#command-line-arguments).

### Docker Environment File for Azure Authentication

Follow either one of the authentication methods that are described in [Authenticating Terraform to access Azure](./TerraformAzureAuthentication.md), and create a file with the authentication variable values to use with container invocation. Store these values outside of this repository in a secure file, such as
`$HOME/.azure_docker_creds.env`. Protect that file with Azure credentials so that only you have Read access to it. **NOTE**: Do not use quotation marks around the values in the file, and be sure to avoid any trailing blank spaces.

#### Public Access Cidrs Environment File

In order to run  ```terraform apply``` integration tests, you will also need to define your ```TF_VAR_public_cidrs``` as described in [Admin Access](../CONFIG-VARS.md#admin-access), and create a file with the public access cidr values to use with container invocation.  Store these values in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) outside of this repository in a secure file, such as `$HOME/.azure_public_cidrs.env`. Protect that file with public access cidr values so that only you have Read access to it. Below is an example of what the file should look like.

```bash
TF_VAR_public_cidrs=["123.456.7.8/16", "98.76.54.32/32"]
```

Now each time you invoke the container, specify the file with the [`--env-file`](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file) option to pass Azure credentials to the container.

### Docker Volume Mounts

Run the following command:
`--volume="$(pwd)":/viya4-iac-azure`
Note that the project must be mounted to the `/viya4-iac-azure` directory.

## Command-Line Arguments

The `terratest_docker_entrypoint.sh` script supports several command-line arguments to customize the test execution. Here are the available options:

* `-p, --package=PACKAGE`: The package to test. Default is './...'
* `-r, --run=TEST`: The name of the test to run. Default is '.\*Plan.\*'.
* `-v, --verbose`: Run the tests in verbose mode.
* `-h, --help`: Display the help message.

## Running Terratest Commands

### Running the Plan Tests

To run the suite of unit tests (only `terraform plan`), run the following Docker command:

```bash
# Run from the ./viya4-iac-azure directory
docker run --rm \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume "$(pwd)":/viya4-iac-azure \
  viya4-iac-azure-terratest
```

### Running the Apply Tests

To run the suite of integration tests (only `terraform apply`), run the following Docker command:

```bash
# Run from the ./viya4-iac-azure directory
docker run --rm \
  --env-file=$HOME/.azure_docker_creds.env \
  --env-file=$HOME/.azure_public_cidrs.env \
  --volume "$(pwd)":/viya4-iac-azure \
  viya4-iac-azure-terratest \
  -r=".*Apply.*"
```

### Running a Specific Go Test

To run a specific test, run the following Docker command with the `-r` option:

```bash
# Run from the ./viya4-iac-azure directory
docker run --rm \
  --env-file=$HOME/.azure_docker_creds.env \
  --env-file=$HOME/.azure_public_cidrs.env \ #env file for integration tests
  --volume "$(pwd)":/viya4-iac-azure \
  viya4-iac-azure-terratest \
  -r="YourTest"
```
To run multiple tests, pass in a regex to the `-r` option - "TestName1|TestName2|TestName3"

####  Running a Specific Integration Go Test

To run a specific integration test, modify the main test runner function (i.e. TestApplyNonDefaultMain) to define the test name you desire and run the following Docker command with the `-r` option:

```bash
# Run from the ./viya4-iac-azure directory
docker run --rm \
  --env-file=$HOME/.azure_docker_creds.env \
  --env-file=$HOME/.azure_public_cidrs.env \
  --volume "$(pwd)":/viya4-iac-azure \
  viya4-iac-azure-terratest \
  -r="YourIntegrationTestMainFunction"
```

### Running a Specific Go Package and Test

If you want to specify the Go package and test name, run the following Docker command with the following options:

```bash
# Run from the ./viya4-iac-azure directory
docker run --rm \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume "$(pwd)":/viya4-iac-azure \
  viya4-iac-azure-terratest \
  -r="YourTest" \
  -p="YourPackage"
```

####  Running a Specific Integration Go Package and Test

To run a specific integration Go package and test name, modify the main test runner function in the desired packaged to define the test name you want and run the following Docker command with the following options:

```bash
# Run from the ./viya4-iac-azure directory
docker run --rm \
  --env-file=$HOME/.azure_docker_creds.env \
  --env-file=$HOME/.azure_public_cidrs.env \
  --volume "$(pwd)":/viya4-iac-azure \
  viya4-iac-azure-terratest \
  -r="YourIntegrationTestMainFunction" \
  -p="YourPackage"
```

### Running the Go Tests with verbose mode

If you want to run the tests in verbose mode, run the Docker command with the `-v` option:

```bash
# Run from the ./viya4-iac-azure directory
docker run --rm \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume "$(pwd)":/viya4-iac-azure \
  viya4-iac-azure-terratest -v
```

### Accessing test run logs

After you have started the Docker container, log files are created in the `./viya4-iac-azure/test/test_output` directory. These files enable you to view the test results in XML format, as well as test logs that are generated by the terrratest_log_parser.