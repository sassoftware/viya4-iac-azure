# Using Docker Container

## Prereqs

- Make sure you have Docker [installed on your workstation](../../README.md#docker).

- Prepare a file with authentication info, as described in [Authenticating Terraform to access Azure](./TerraformAzureAuthentication.md)

## Build the docker image

Run the following command to create the `viya4-iac-azure` docker image that will be used in subsequent steps:

```bash
docker build -t viya4-iac-azure .
```

NOTE: The Dockerfile for the container can be found [here](../../Dockerfile).

## Preparation

Add volume mounts to the `docker run` command for all files and directories that must be accessible from inside the container.

The most common file reference is the value of the [`ssh_public_key`](./CONFIG-VARS.md#required-variables) variable in the `terraform.tfvars` file.

Note that local references to `$HOME` (or "`~`") need to map to the root directory `/` in the container.

## Preview Cloud Resources (optional)

To preview which resources will be created, run

```bash
docker run --rm -u "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  plan -var-file=/workspace/terraform.tfvars \
       -state=/workspace/terraform.tfstate  
```

## Create Cloud Resources

To create the cloud resources, run

```bash
docker run --rm -u "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state=/workspace/terraform.tfstate 
```
This command can take a few minutes to complete. Once complete, output values are written to the console.

The kubeconfig file for the cluster is being written to `[prefix]-aks-kubeconfig.conf` in the current directory `$(pwd)`.

## Display Outputs

The output values can be displayed anytime again by running

```bash
docker run --rm -u "$(id -u):$(id -g)" \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  output -state=/workspace/terraform.tfstate 
 
```

## Modify Cloud Resources

After provisioning the infrastructure if further changes were to be made then add the variable and desired value to `terraform.tfvars` and run again:

```bash
docker run --rm -u "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state=/workspace/terraform.tfstate 
```


## Tear Down Resources 

To destroy the cloud resources created with the previous commands, run

```bash
docker run --rm -u "$(id -u):$(id -g)" \
  --env-file=$HOME/.azure_docker_creds.env \
  --volume=$HOME/.ssh:/.ssh \
  --volume=$(pwd):/workspace \
  viya4-iac-azure \
  destroy -auto-approve \
          -var-file=/workspace/terraform.tfvars \
          -state=/workspace/terraform.tfstate
```
NOTE: The "destroy" action is irreversible.

## Interacting with Kubernetes cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file `./[prefix]-eks-kubeconfig.conf`. When the Kubernetes cluster is ready, use `--entrypoint kubectl` to interact with the cluster.

**Note** this requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

### Using `kubectl` Example

```bash
docker run --rm \
  --env=KUBECONFIG=/workspace/<your prefix>-eks-kubeconfig.conf \
  --volume=$(pwd):/workspace \
  --entrypoint kubectl \
  viya4-iac-gcp get nodes 

```
