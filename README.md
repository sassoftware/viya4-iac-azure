# SAS Viya 4 IaC for Azure

## Overview

This project contains Terraform configuration files to provision infrastructure components required to deploy SAS Viya 4+ VA/VS/VDMML products on Microsoft Azure Cloud.

### What's New

* First public release.

### Prerequisites

You must be familiar with terraform, kubernetes and the Azure CLI.

#### Required
 * [Terraform](https://www.terraform.io/downloads.html) - v0.13.2
 * Access to an Azure Subscription and a Service Principal with 'Contributor' role

#### Optional
 * [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) - v2.1.0
   * Only needed for authentication if you do not already have a Service Principal. 
   * The azure CLI does come in handy as an alternative to the Azure UI for checking resources and profile information.

## Getting Started

### Clone / Working Directory

```
# Clone this repo
git clone https://github.com/sassoftware/viya4-iac-azure

# Move to directory
cd viya4-iac-azure
```

### Running

#### Authenticating Terraform to access Azure

In order to create and destroy Azure objects for you, Terraform needs to know your Azure Tenant and Subscription ids, as well as a user identifier and password.

Terraform supports multiple ways of authenticating to Azure.

**TODO:** - Update link below to refernce correctly on GitHub

In order to fully support automation, this project chooses to use an Azure Service Principal for authentication.

You can follow the steps on [Azure Help Topics](./docs/user/AzureHelpTopics.md) to get the values for
 * `SUBSCRIPTION_ID`
 * `TENANT_ID`

 and to create Service Principal to get
 * `SP_APPID`
 * `SP_PASSWD`

**Note** You need to create your Service Principal only once. Keep track of your `SP_APPID` and `SP_PASSWORD` in a secure file, you will need them in the next step, when you initialize your Terraform environment.

Run these commands to initialize the environment for the project. These commands will need to be run and pulled into your environment each time you start a new session to use this repo and terraform.

```
# export needed ids and secrets
export ARM_SUBSCRIPTION_ID=[SUBSCRIPTION_ID]
export ARM_TENANT_ID=[TENANT_ID]
export ARM_CLIENT_ID=[SP_APPID]
export ARM_CLIENT_SECRET=[SP_PASSWD]

export TF_VAR_client_id=[SP_APPID]
export TF_VAR_client_secret=[SP_PASSWD]
```
**TIP:** These commands can be stored in a file outside of this repo in a secure file. \
Use your favorite editor, take the content above and save it to a file called: `$HOME/.azure_creds.sh` \
Now each time you need these values you can do the following:

```
source $HOME/.azure_creds.sh
```

This will pull in those values into your current terminal session and you are ready to go.

#### Terraform - Init

Now run this command to initialize Terraform for this project.

```
terraform init
```

**NOTE:** This command only needs to be run once.

#### Terraform - Plan

Terraform accepts inputs when prompted or you can conveniently pass them into the command line with ```-var``` or ```-var-file``` options. This overrides any default values in ```variables.tf```

**NOTE:** See the provided ```sample-input*.tfvars``` files to customize your inputs to the ```plan``` command.

> Information on the variables used in the sample variable files can be found here:
>  * [CONFIG-VARS.md](docs/CONFIG-VARS.md)

```
# to generate a terraform plan
terraform plan -var-file=sample-input.tfvars -out ./my-aks.plan
```

Once initialized, the ```terraform plan``` command can be run multiple times to generate a plan to review prior to actually creating cloud resources. This is helpful to 
1) verify that the Terraform script runs with no errors
2) review the cloud resources before creating them
3) when run after infrastructure has been created with '*terraform apply*' it diffs between the local definitions and the actual infrastructure 

#### Terraform - Show

Run ```terraform show``` command to display the plan again

    # to review the plan
    terraform show my-aks.plan

#### Terraform - Apply

After any errors are resolved and satisfied with the plan, run the ```terraform apply``` command to create resources on the cloud provider. When a plan file is not provided, Terraform generates a plan at that time that may differ from previous ```plan``` runs.  

    # run apply to create resources based on the plan
    terraform apply ./my-aks.plan

#### Terraform - State

After the resouces are created use ```terraform state list``` to list all the resources and ```terraform state show``` to get details of a resource.

    terraform state list 
    # to get more details on a partictular resource 
    terraform state show <resource-name-from-state-list>

#### Terraform - Output

To display the outputs captured by terraform you can use the `terraform output` command to show all or a specific output variable.

    terraform output
    # to get a specific output variable
    terraform output <output-variable>

#### Interacting with kubernetes

Now that you have your kubernetes cluster up and running, here's how to connect to the cluster:

**NOTE:** The kubeconfig is already written out to ./[prefix]-aks-kubeconfig.conf

    terraform output kube_config > ./[prefix]-aks-kubeconfig.conf
    export KUBECONFIG=./[prefix]-aks-kubeconfig.conf
    kubectl get nodes

### Examples

We include several sample files in this repo. These files are a great starting point for any developer. Simply read through the files and see which one fits your current needs. Evaulate the file, then review the [CONFIG-VARS.md](docs/CONFIG-VARS.md) listed above to see what other variables can be used.

### Troubleshooting

There is a bug that has no real owner at this time that sometimes requires one to run the `terraform destroy` command twice before all resources are removed from terraform.

Here is a sample of the error:

```
Error: waiting for the deletion of Node Pool "stateful" (Managed Kubernetes Cluster "viya-tst1-aks" / Resource Group "viya-tst1-rg"): Code="Canceled" Message="The operation was overriden and canceled by a later operation e99c6c8f-18cb-46de-8142-4c87b7a2add0."
```

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project. 

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

### Azure
* Azure CLI - https://docs.microsoft.com/en-gb/cli/azure/?view=azure-cli-latest
* Terraform install & configure for Azure - https://docs.microsoft.com/en-us/azure/terraform/terraform-install-configure
* AKS - https://docs.microsoft.com/en-us/azure/aks/intro-kubernetes
* Service Principal for AKS - https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal
* Terraform on Azure - https://docs.microsoft.com/en-us/azure/terraform/
* Tutorial: AKS using Terraform - https://docs.microsoft.com/en-us/azure/terraform/terraform-create-k8s-cluster-with-tf-and-aks
* Azure Active Directory(AD) & Service Principal(SP) concepts - https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals
### Terraform 
* Azure Provider  https://www.terraform.io/docs/providers/azurerm/guides/azure_cli.html#logging-into-the-azure-cli
* Azure AKS - https://www.terraform.io/docs/providers/azurerm/d/kubernetes_cluster.html
