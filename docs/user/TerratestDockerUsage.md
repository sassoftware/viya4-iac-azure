# Using the Terratest Docker Container

## Prereqs

- Docker [installed on your workstation](../../README.md#docker).

## Preparation

### Docker image

Run the following command to create the `viya4-iac-azure-terratest` Docker image using the provided [Dockerfile.terratest](../../Dockerfile.terratest)

```bash
docker build -t viya4-iac-azure-terratest -f Dockerfile.terratest .
```
The Docker image `viya4-iac-azure-terratest` will contain Terraform and 'go' executables, as well as the required go modules. The Docker entrypoint for the image is `go test` and accepts several optional command-line arguments.

### Docker Environment File for Azure Authentication

Follow either one of the authentication methods described in [Authenticating Terraform to access Azure](./TerraformAzureAuthentication.md) and create a file with the authentication variable values to use with container invocation. Store these values outside of this repo in a secure file, for example
`$HOME/.azure_docker_creds.env.` Protect that file with Azure credentials so only you have read access to it. **NOTE:** Do not use quotes around the values in the file, and make sure to avoid any trailing blanks!

Now each time you invoke the container, specify the file with the [`--env-file` option](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file) to pass on Azure credentials to the container.

## Options
The `terratest_docker_entrypoint.sh` script supports several options to customize the test execution. Here are the available options:

`-p, --package=PACKAGE`: The package to test. Default is '.'.
`-n, --testname=TEST`: The name of the test to run. Default is 'TestDefaults'.
`-t, --build-tags=TAGS`: The tags to use when running the tests. Default is `'integration_plan_unit_tests'`.
`-v, --verbose`: Run the tests in verbose mode.
`-h, --help`: Display the help message.

## Running Terratest Commands

### Running the default tests

To run the default suite of tests, run the docker image:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  viya4-iac-azure-terratest
```

### Running a specific Go Test

To run a specific test, run the docker image with the -n argument:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  viya4-iac-azure-terratest \
  -n YourTest
```
To run multiple tests, pass in a regex to the -n argument - 'TestName1|TestName2|TestName3'



### Running a specific Go Package, Test, and Build Tags

If you want to specify the Go package, Test name, and Build Tags, run the docker image with the following arguments:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  viya4-iac-azure-terratest \
  -n=YourTest \
  -p=YourPackage \
  -t=YourBuildTags
```

### Running the Go Tests with verbose mode

If you want to run the tests with verbose mode, run the docker image with the -v flag:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  viya4-iac-azure-terratest -v
```


### Testing your local changes 

After making changes, mount the ./viya4-iac-azure/test directory to /viya4-iac-azure/test. This will pick up your latest changes and use them for the go test 


```bash
# Run from the /viya4-iac-azure root
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  -v=$(pwd)/test:/viya4-iac-azure/test
  viya4-iac-azure-terratest
```