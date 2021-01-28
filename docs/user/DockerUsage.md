# Using Docker Container

## Prereqs

- Docker [installed on your workstation](../../README.md#docker).

## Build the Docker image

Run the following command to create the `viya4-iac-azure` Docker image using the provided [Dockerfile](../../Dockerfile)

```bash
docker build -t viya4-iac-azure .
```
The Docker image `viya4-iac-azure` will contain Terraform and 'kubectl' executables. The Docker entrypoint for the image is `terraform` that will be run with sub-commands in the subsequent steps.

## Prepare Docker Environment File for Azure Authentication

Follow either one of the authentication methods described in [Authenticating Terraform to access Azure](./TerraformAzureAuthentication.md) and create a file with the authentication variable values to use with container invocation. Store these values outside of this repo in a secure file, for example
`$HOME/.azure_docker_creds.env`. Protect that file with Azure credentials so only you have read access to it. **NOTE:** Do not use quotes around the values in the file, and make sure to avoid any trailing blanks!

Now each time you invoke the container, specify the file with the [`--env-file` option](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file) to pass on Azure credentials to the container e.g.

```bash
docker run <...> \
  --env-file $HOME/.azure_docker_creds.env \
  <...>
```

## Configure Docker Volume Mounts

Add volume mounts to the `docker run` command for all files and directories that must be accessible from inside the container. 
- `--volume=$HOME/.ssh:/.ssh` for [`ssh_public_key`](../CONFIG-VARS.md#required-variables) variable in the `terraform.tfvars` file
- `--volume=$(pwd):/workspace` for local directory where `terraform.tfvars` file resides and where `terraform.tfstate` file will be written

**Note** that local references to `$HOME` (or "`~`") need to map to the root directory `/` in the container.

To grant Docker, permission to write to the local directory use [`--user` option](https://docs.docker.com/engine/reference/run/#user)

```bash
docker run <...> \
  --user "$(id -u):$(id -g)" \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  <...>
```

## Preview Cloud Resources (optional)

To preview the cloud resources before creating, run the Docker image `viya4-iac-azure` with the `plan` command

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  plan -var-file=/workspace/terraform.tfvars \
       -state=/workspace/terraform.tfstate  
```

## Create Cloud Resources

To create the cloud resources, run the Docker image `viya4-iac-azure` with the `apply` command and `-auto-approve` option

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state=/workspace/terraform.tfstate 
```
This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. The 'KUBECONFIG' file for the cluster is written to `[prefix]-aks-kubeconfig.conf` in the current directory `$(pwd)`.

## Display Outputs

Once the cloud resources have been created with above command and to display Terraform output values, run the Docker image `viya4-iac-azure` with `output` command

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  output -state=/workspace/terraform.tfstate  
```

## Modify Cloud Resources

After provisioning the infrastructure if further changes were to be made then update corresponding variables with desired values in `terraform.tfvars` and run the Docker image `viya4-iac-azure` with the `apply` command and `-auto-approve` option again

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state=/workspace/terraform.tfstate 
```

## Tear Down Cloud Resources 

To destroy the cloud resources created with the previous commands, run the Docker image `viya4-iac-azure` with the `destroy` command and `-auto-approve` option

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  destroy -auto-approve \
          -var-file=/workspace/terraform.tfvars \
          -state=/workspace/terraform.tfstate
```
**NOTE:** The 'destroy' action is irreversible.

## Interacting with Kubernetes cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file `./[prefix]-aks-kubeconfig.conf`. When the Kubernetes cluster is ready, use `--entrypoint kubectl` to interact with the cluster.

**Note** this requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

### Using `kubectl` Example

To run `kubectl` with the Docker image `viya4-iac-azure`, change entrypoint to kubectl (`--entrypoint kubectl`), provide 'KUBECONFIG' value (`--env=KUBECONFIG=/workspace/<your prefix>-aks-kubeconfig.conf`) and pass in kubectl subcommands. For e.g., to run `kubectl get nodes` to list cluster nodes

```bash
docker run --rm \
  --env=KUBECONFIG=/workspace/<your prefix>-aks-kubeconfig.conf \
  --volume=$(pwd):/workspace \
  --entrypoint kubectl \
  viya4-iac-gcp get nodes 
```
