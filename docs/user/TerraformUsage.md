# Using the Terraform Command-Line Interface

Use Terraform and the SAS IaC tools to create a Kubernetes cluster for your SAS Viya deployment.

## Prepare the Environment

### Prerequisites
When using the Terraform CLI, make sure you have all the necessary tools [installed on your workstation](../../README.md#terraform-requirements).

### Set Up Microsoft Azure Authentication

Follow either one of the authentication methods described in [Authenticating Terraform to Access Azure](./TerraformAzureAuthentication.md) and set all TF_VAR_name environment variables using `export TF_VAR_*=<value>` command.  If you are unsure which Terraform environment variables are required, review the commands that are included in the optional bash script that is described in *Tip: Alternative Option 2*.

> *Tip: Alternative Option 1:*  The commands to set the TF_VAR_name environment variables can be securely stored in a file outside of this repository, for example `$HOME/.azure_creds.sh.` Remember to protect that file so that only you have Read access to it.

Then source your credentials into your shell environment:

```bash
. $HOME/.azure_creds.sh
```

> *Tip: Alternative Option 2:*  Once you have authenticated to the `az cli`, you can source the following
[bash (code) script](../../files/tools/terraform_env_variable_helper.sh), which can be used to assign or reassign the Terraform environment variables:

```bash
# source the bash script, presuming the file path
source files/tools/terraform_env_variable_helper.sh
```

### Customize Terraform Input Variables (tfvars)

Create a file named `terraform.tfvars` to customize any input variable value. To get started, copy one of the example variable definition files that are provided
in the `./examples` folder: 

```bash
# Example copy command
cp examples/sample-input.tfvars terraform.tfvars
```

For more information about the variables that are declared in [variables.tf](variables.tf), refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

## Run Terraform Commands

### Initialize Terraform Environment

Initialize the Terraform environment for this project by running the following command:

```bash
terraform init
```

This creates a `.terraform` directory locally and initializes the Terraform plug-ins and modules that are used in this project.

**Note:** The `terraform init` command only needs to be run once unless new Terraform plug-ins or modules are added.

### (Optional) Preview Cloud Resources

To preview the cloud resources before creating them, run:

```bash
terraform plan
# alternative to store your plan for later: terraform plan -out=~/tf-plan.out 
```
### Create Cloud Resources

To create cloud resources, run:

```bash
terraform apply -auto-approve
```

This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. The 'KUBECONFIG' file for the cluster is written to `[prefix]-aks-kubeconfig.conf` in the current directory `$(pwd)`.

### Display Output Values

Once the cloud resources have been created with the `apply` command, run the following command to display Terraform output values: 

```bash
terraform output
```

### Modify Cloud Resources

After provisioning the infrastructure, if further changes are required, add the variable and desired value to `terraform.tfvars` and run `terrafom apply` again.


### Tear Down Cloud Resources

To destroy all the cloud resources created with the previous commands, run:

```bash
terraform destroy
```
_**NOTE**_: The "destroy" action is irreversible.

## Interact with the Kubernetes Cluster

The command to [create the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file, `./[prefix]-aks-kubeconfig.conf.` When the Kubernetes cluster is ready, use `kubectl` to interact with the cluster and perform the SAS Viya deployment.

_**IMPORTANT**_ The value for [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) must be set to your local IP address or CIDR range.

### Example Using `kubectl` 

```bash
export KUBECONFIG=$(pwd)/<your prefix>-aks-kubeconfig.conf
kubectl get nodes
```
