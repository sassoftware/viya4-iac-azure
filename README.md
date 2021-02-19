# SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure

## Overview

This project contains Terraform scripts to provision Microsoft Azure Cloud infrastructure resources required to deploy SAS Viya 4 products. Here is a list of resources this project can create -

  >- Azure Resource Group
  >- Virtual Network, Network Security Groups and Network Security Rules
  >- Managed Azure Kubernetes Service (AKS) cluster
  >- System and User AKS Node pools with required Labels and Taints
  >- Infrastructure to deploy SAS Viya CAS in SMP or MPP mode
  >- Storage options for SAS Viya -  AzureDisk/Files(dev) or NFS Server or Azure NetApp Files(HA)
  >- Azure DB for PostgreSQL, optional
  >- Azure Container Registry, optional

[<img src="./docs/images/viya4-iac-azure-diag.png" alt="Architecture Diagram" width="750"/>](./docs/images/viya4-iac-azure-diag.png?raw=true)

## Prerequisites

Operational knowledge of:

- [Terraform](https://www.terraform.io/intro/index.html)
- [Docker](https://www.docker.com/)
- [Microsoft Azure Cloud](https://azure.microsoft.com/)
- [Kubernetes](https://kubernetes.io/docs/concepts/)
 
### Required

- Access to an **Azure Subscription** and [**Identity**](./docs/user/TerraformAzureAuthentication.md) with '*Contributor*' role
- Terraform or Docker
  - #### Terraform
    - [Terraform](https://www.terraform.io/downloads.html) - v0.13.6
    - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) - v1.18.8
    - [jq](https://stedolan.github.io/jq/) - v1.6
    - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure) - v2.19.1 (optional -useful as an alternative to the AWS Web Console)
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

Create a file named `terraform.tfvars` to customize any input variable value. For starters, you can copy one of the provided example variable definition files in `./examples` folder. For more details on the variables declared in [variables.tf](variables.tf) refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

## Creating and Managaging the Cloud Resources

Create and manage the AWS cloud resources by either 

- using [Terraform](docs/user/TerraformUsage.md) directly on your workstation, or
- using a [Docker container](docs/user/DockerUsage.md). 

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
