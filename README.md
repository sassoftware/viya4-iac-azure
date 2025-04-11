# SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
   - [Technical Prerequisites](#technical-prerequisites)
   - [Terraform Requirements](#terraform-requirements)
   - [Docker Requirements](#docker-requirements)
3. [Getting Started](#getting-started)
   - [Clone this Project](#clone-this-project)
   - [Authenticating Terraform to Access Microsoft Azure](#authenticating-terraform-to-access-microsoft-azure)
   - [Customizing Input Values](#customizing-input-values)
4. [Creating and Managing the Cloud Resources](#creating-and-managing-the-cloud-resources)
5. [Troubleshooting](#troubleshooting)
6. [Security](#security)
7. [Contributing](#contributing)
8. [License](#license)
9. [Additional Resources](#additional-resources)
   - [Azure Resources](#azure-resources)
   - [Terraform Resources](#terraform-resources)

## Overview

This project helps you to automate the cluster-provisioning phase of SAS Viya platform deployment. It contains Terraform scripts to provision the Microsoft Azure Cloud infrastructure resources that are required to deploy SAS Viya platform product offerings. Here is a list of resources that this project can create:

  >- Azure resource group(s): primary resource group and AKS resource group
  >- Virtual network, network security groups, and network security rules
  >- Managed Azure Kubernetes Service (AKS) cluster
  >- System and User AKS Node pools with required Labels and Taints
  >- Infrastructure to deploy SAS Viya platform CAS in SMP or MPP mode
  >- Storage options for SAS Viya platform -  NFS Server (Standard) or Azure NetApp Files (HA)
  >- Azure DB for PostgreSQL, optional
  >- Azure Container Registry, optional

[<img src="./docs/images/viya4-iac-azure-diag.png" alt="Architecture Diagram" width="750"/>](./docs/images/viya4-iac-azure-diag.png?raw=true)

This project addresses the first of three steps in [Steps for Getting Started](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopscon&docsetTarget=n12fgslcw9swbsn10rva4bp0mr2w.htm) in _SAS&reg; Viya&reg; Platform Operations_:

1. Provision resources.
1. Prepare for the deployment.
1. Customize and deploy the SAS Viya platform.

**Note:** The scripts in this project are provided as examples. They do not provide comprehensive configuration. The second and third steps include additional configuration tasks. Some of those tasks (for example, enabling logging and specifying available IP addresses) are essential for a more secure deployment.

Once the cloud resources are provisioned, use the [viya4-deployment](https://github.com/sassoftware/viya4-deployment) project to deploy 
the SAS Viya platform in your cloud environment. To learn about all phases and options of the SAS Viya platform deployment process, see
[Getting Started with SAS Viya and Azure Kubernetes Service](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopscon&docsetTarget=n1d7qc4nfr3s5zn103a1qy0kj4l1.htm) in _SAS Viya Platform Operations_.


This project follows the [SemVer](https://semver.org/#summary) versioning scheme. Given a version number MAJOR.MINOR.PATCH, we increment the:

 >- MAJOR version when we make changes that are incompatible with the functionality of a previous component
 >- MINOR version when we add functionality that is backwards-compatible
 >- PATCH version when we make bug fixes that are backwards-compatible

**Note**: You must take down your existing infrastructure and rebuild it when you are upgrading to a new major version because of potential backward incompatibility. For details about the changes that are added in each release, see the Release Notes.

## Prerequisites

Use of these tools requires operational knowledge of the following technologies:

- [Terraform](https://www.terraform.io/intro/index.html)
- [Docker](https://www.docker.com/)
- [Microsoft Azure Cloud](https://azure.microsoft.com/)
- [Kubernetes](https://kubernetes.io/docs/concepts/)
 

### Technical Prerequisites

This project supports two options for running Terraform scripts:
- Terraform installed on your local machine
- Using a Docker container to run Terraform
  
  For more information, see [Docker Usage](./docs/user/DockerUsage.md). Using Docker to run the Terraform scripts is recommended.

Access to an **Azure Subscription** and an [**Identity**](./docs/user/TerraformAzureAuthentication.md) with the *Contributor* role are required.

#### Terraform Requirements:
- [Terraform](https://www.terraform.io/downloads.html) - v1.10.5
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) - v1.31.6
- [jq](https://stedolan.github.io/jq/) - v1.6
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure) - (optional - useful as an alternative to the Azure Portal) - v2.70.0

#### Docker Requirements:
- [Docker](https://docs.docker.com/get-docker/)

## Getting Started

When you have prepared your environment with the prerequisites, you are ready to obtain and customize the Terraform scripts that
will set up your Kubernetes cluster.

### Clone this Project

Run the following commands from a terminal session:

```bash
# clone this repo
git clone https://github.com/sassoftware/viya4-iac-azure

# move to the project directory
cd viya4-iac-azure
```

### Authenticating Terraform to Access Microsoft Azure

The Terraform process manages Microsoft Azure resources on your behalf. In order to do so, it needs your Azure account information and a user
identity with the required permissions. See [Terraform Azure Authentication](./docs/user/TerraformAzureAuthentication.md) for details.

### Customizing Input Values

Terraform scripts require variable definitions as input. Review and modify default values to meet your requirements. Create a file named
`terraform.tfvars` to customize any input variable value documented in the [CONFIG-VARS.md](docs/CONFIG-VARS.md) file. 

To get started, you can copy one of the example variable definition files provided in the `./examples` folder. For more information about the
variables that are declared in each file, refer to the [CONFIG-VARS.md](docs/CONFIG-VARS.md) file.

You have the option to specify variable definitions that are not included in `terraform.tfvars` or to use a variable definition file other than
`terraform.tfvars`. See [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for more information.

## Creating and Managing the Cloud Resources

Create and manage the required cloud resources. Perform one of the following steps, based on whether you are using Docker: 

- run [Terraform](docs/user/TerraformUsage.md) directly on your workstation
- run the [Docker container](docs/user/DockerUsage.md) (recommended)

### Troubleshooting

See the [Troubleshooting](./docs/Troubleshooting.md) page for information about possible issues that you might encounter.

## Security

Additional configuration to harden your cluster environment is supported and encouraged. For example, you can limit cluster access to specified IP addresses. You can also deploy a load balancer or application gateway to mediate data flows between SAS Viya platform components and the ingress controller.

## Contributing

> We welcome your contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for information about how to submit contributions to this project.

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

### Azure Resources

- [Azure CLI](https://docs.microsoft.com/en-gb/cli/azure/?view=azure-cli-latest)
- [Terraform on Azure](https://docs.microsoft.com/en-us/azure/terraform)
- [Configure Terraform access to Azure](https://docs.microsoft.com/en-us/azure/terraform/terraform-install-configure)
- [AKS intro](https://docs.microsoft.com/en-us/azure/aks/intro-kubernetes)
- [Service Principal for AKS](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal)
- [Create AKS using Terraform](https://docs.microsoft.com/en-us/azure/terraform/terraform-create-k8s-cluster-with-tf-and-aks)
- [Azure Active Directory(AD) & Service Principal(SP) concepts](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)

### Terraform Resources

- [Azure Provider](https://www.terraform.io/docs/providers/azurerm/index.html)
- [Azure AKS](https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster)
