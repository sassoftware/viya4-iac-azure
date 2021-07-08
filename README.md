# SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure

BRANCH EDIT #3

## Overview

This project contains Terraform scripts to provision Microsoft Azure Cloud infrastructure resources required to deploy SAS Viya 4 products. Here is a list of resources this project can create -

  >- Azure Resource Group(s): Primary Resource Group and AKS Resource Group
  >- Virtual Network, Network Security Groups and Network Security Rules
  >- Managed Azure Kubernetes Service (AKS) cluster
  >- System and User AKS Node pools with required Labels and Taints
  >- Infrastructure to deploy SAS Viya CAS in SMP or MPP mode
  >- Storage options for SAS Viya -  AzureDisk/Files(dev) or NFS Server or Azure NetApp Files(HA)
  >- Azure DB for PostgreSQL, optional
  >- Azure Container Registry, optional

[<img src="./docs/images/viya4-iac-azure-diag.png" alt="Architecture Diagram" width="750"/>](./docs/images/viya4-iac-azure-diag.png?raw=true)

Once the cloud resources are provisioned, see the [viya4-deployment](https://github.com/sassoftware/viya4-deployment) repo to deploy SAS Viya 4 products. If you need more information on the SAS Viya 4 products refer to the official [SAS&reg; Viya&reg; 4 Operations](https://go.documentation.sas.com/?cdcId=itopscdc&cdcVersion=v_001LTS&docsetId=itopswlcm&docsetTarget=home.htm&locale=en) documentation for more details.

## Prerequisites

### Operational knowledge of:

- [Terraform](https://www.terraform.io/intro/index.html)
- [Docker](https://www.docker.com/)
- [Microsoft Azure Cloud](https://azure.microsoft.com/)
- [Kubernetes](https://kubernetes.io/docs/concepts/)


### Technical Prerequisites:

This project supports running **either** via terraform installed on your local machine **or** via a docker container.

- Access to an **Azure Subscription** and [**Identity**](./docs/user/TerraformAzureAuthentication.md) with '*Contributor*' role
  - #### Terraform
    - [Terraform](https://www.terraform.io/downloads.html) - v1.0.0
    - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) - v1.19.9
    - [jq](https://stedolan.github.io/jq/) - v1.6
    - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure) - (optional - useful as an alternative to the Azure Portal) - v2.24.2
  - #### Docker
    - [Docker](https://docs.docker.com/get-docker/)


## Getting Started

### Clone this project

Run these commands in a Terminal session:

```bash
# clone this repo
git clone https://github.com/sassoftware/viya4-iac-azure

# move to directory
cd viya4-iac-azure
```

### Authenticating Terraform to access Azure

See [Terraform Azure Authentication](./docs/user/TerraformAzureAuthentication.md) for details.

### Customize Input Values

Create a file named `terraform.tfvars` to customize any input variable value documented in the [CONFIG-VARS.md](docs/CONFIG-VARS.md) file. For starters, you can copy one of the provided example variable definition files in `./examples` folder. For more details on the variables declared refer to the [CONFIG-VARS.md](docs/CONFIG-VARS.md) file.

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

## Creating and Managing the Cloud Resources

Create and manage the cloud resources by either:

- running [Terraform](docs/user/TerraformUsage.md) directly on your workstation, or
- running [Docker container](docs/user/DockerUsage.md).

### Troubleshooting

See [troubleshooting](./docs/Troubleshooting.md) page.

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project.

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

### Azure resources

- [Azure CLI](https://docs.microsoft.com/en-gb/cli/azure/?view=azure-cli-latest)
- [Terraform on Azure](https://docs.microsoft.com/en-us/azure/terraform)
- [Configure Terraform access to Azure](https://docs.microsoft.com/en-us/azure/terraform/terraform-install-configure)
- [AKS intro](https://docs.microsoft.com/en-us/azure/aks/intro-kubernetes)
- [Service Principal for AKS](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal)
- [Create AKS using Terraform](https://docs.microsoft.com/en-us/azure/terraform/terraform-create-k8s-cluster-with-tf-and-aks)
- [Azure Active Directory(AD) & Service Principal(SP) concepts](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)

### Terraform resources

- [Azure Provider](https://www.terraform.io/docs/providers/azurerm/index.html)
- [Azure AKS](https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html)
