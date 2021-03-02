# Using the Terraform CLI

## Prereqs
When using the Terraform CLI, make sure you have all the necessary tools [installed on your workstation](../../README.md#terraform).

## Preparation

### Set Azure Authentication

Follow either one of the authentication methods described in [Authenticating Terraform to access Azure](./TerraformAzureAuthentication.md) and set all TF_VAR_name environment variables using `export TF_VAR_*=<value>` command.

*TIP:* These commands can be stored in a file outside of this repo in a secure file, for example `$HOME/.azure_creds.sh.` Protect that file so only you have read access to it.

Then source your credentials into your shell environment:

```bash
. $HOME/.azure_creds.sh
```

### Customize TF Input Variables (tfvars)

Create a file named `terraform.tfvars` to customize any input variable value. For starters, you can copy one of the provided example variable definition files in `./examples` folder. 

```bash
# Example copy command
cp examples/sample-input.tfvars terraform.tfvars
```

For more details on the variables declared in [variables.tf](variables.tf) refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

## Running Terraform Commands

### Initialize Terraform Environment

Initialize the Terraform environment for this project by running

```bash
terraform init
```

This creates a `.terraform` directory locally and initializes Terraform plugins and modules used in this project.

**Note:** `terraform init` only needs to be run once unless new Terraform plugins/modules were added.

### Preview Cloud Resources (optional)

To preview the cloud resources before creating, run

```bash
terraform plan
```
### Create Cloud Resources

To create cloud resources, run

```bash
terraform apply -auto-approve
```

This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. The 'KUBECONFIG' file for the cluster is written to `[prefix]-aks-kubeconfig.conf` in the current directory `$(pwd)`.

### Display Outputs

Once the cloud resources have been created with `apply` command, to display Terraform output values, run 

```bash
terraform output
```

### Modify Cloud Resources

After provisioning the infrastructure, if further changes were to be made then add the variable and desired value to `terraform.tfvars` and run `terrafom apply` again.


### Tear Down Cloud Resources

To destroy all the cloud resources created with the previous commands, run

```bash
terraform destroy
```
NOTE: The "destroy" action is irreversible.

## Interacting With The Kubernetes Cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file `./[prefix]-aks-kubeconfig.conf.` When the Kubernetes cluster is ready, use `kubectl` to interact with the cluster.

**Note** this requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

### Example Using `kubectl` 

```bash
export KUBECONFIG=$(pwd)/<your prefix>-aks-kubeconfig.conf
kubectl get nodes
```
