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

The Docker image `viya4-iac-azure-terratest` will contain Terraform and Go executables, as well as the required Go modules. The Docker entrypoint for the image is `go test` and accepts several optional command line arguments. For more information on command line arguments, please see [Command Line Arguments](#command-line-arguments).

### Docker Environment File for Azure Authentication

Follow either one of the authentication methods described in [Authenticating Terraform to access Azure](./TerraformAzureAuthentication.md) and create a file with the authentication variable values to use with container invocation. Store these values outside of this repo in a secure file, for example
`$HOME/.azure_docker_creds.env.` Protect that file with Azure credentials so only you have read access to it. **NOTE:** Do not use quotes around the values in the file, and make sure to avoid any trailing blanks!

Now each time you invoke the container, specify the file with the [`--env-file` option](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file) to pass on Azure credentials to the container.

### Docker Volume Mounts

Add volume mounts to the `docker run` command for all files and directories that must be accessible from inside the container.
- `--volume=$(pwd):/viya4-iac-azure/test` to overwrite the docker image's /viya4-iac-azure/test directory with your own. This will let you test out any local test changes without having to rebuild the docker image.

## Command Line Arguments

The `terratest_docker_entrypoint.sh` script supports several command line arguments to customize the test execution. Here are the available options:

* `-p, --package=PACKAGE`: The package to test. Default is '.'  
* `-n, --testname=TEST`: The name of the test to run. Default is 'TestDefaults'.  
* `-t, --build-tags=TAGS`: The tags to use when running the tests. Default is 'integration_plan_unit_tests'.  
* `-v, --verbose`: Run the tests in verbose mode.  
* `-h, --help`: Display the help message.  

## Running Terratest Commands

### Running the default tests

To run the default suite of unit tests (only terraform plan), run the following docker command:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  viya4-iac-azure-terratest
```

### Running a specific Go Test

To run a specific test, run the following docker command with the -n command line argument:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  viya4-iac-azure-terratest \
  -n="YourTest"
```
To run multiple tests, pass in a regex to the -n argument - "TestName1|TestName2|TestName3"

### Running a specific Go Package, Test, and Build Tags

If you want to specify the Go package, test name, and build tags, run the following docker command with the following arguments:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  viya4-iac-azure-terratest \
  -n="YourTest" \
  -p="YourPackage" \
  -t="YourBuildTags"
```

### Running the Go Tests with verbose mode

If you want to run the tests with verbose mode, run the docker image with the -v flag:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  viya4-iac-azure-terratest -v
```

### Testing changes locally

After making additions or changes to the tests, you can mount the test directory to /viya4-iac-azure/test. This will overwrite the docker image's tests with your latest changes. To do that, run the following docker command:

```bash
# Run from the /viya4-iac-azure root
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  -v=$(pwd)/test:/viya4-iac-azure/test
  viya4-iac-azure-terratest
```
