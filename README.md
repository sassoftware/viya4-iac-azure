# SAS Viya Infrastructure as Code (IaC) for Microsoft Azure

## Overview

This project contains Terraform scripts to provision the Microsoft Azure Cloud infrastructure resources that are required to deploy SAS Viya product offerings. Here is a list of resources that this project can create:

  >- Azure resource group(s): primary resource group and AKS resource group
  >- Virtual network, network security groups, and network security rules
  >- Managed Azure Kubernetes Service (AKS) cluster
  >- System and user AKS node pools with required labels and taints
  >- Infrastructure to deploy the SAS Viya CAS server in SMP or MPP mode
  >- Storage options for SAS Viya:  Azure Premium Managed Disks (standard deployments); NFS Server or Azure NetApp Files (HA deployments)
  >- Azure Database for PostgreSQL (optional)
  >- Azure Container Registry (optional)

[<img src="./docs/images/viya4-iac-azure-diag.png" alt="Architecture Diagram" width="750"/>](./docs/images/viya4-iac-azure-diag.png?raw=true)

Once the cloud resources are provisioned, use the SAS Viya Deployment Operator to deploy SAS Viya in your cloud environment. For more information
about SAS Viya requirements and documentation for the deployment process, refer to the 
[SAS&reg; Viya&reg; IT Operations Guide](https://go.documentation.sas.com/doc/en/itopscdc/v_015/itopswlcm/home.htm).

## Prerequisites

Use of these tools requires operational knowledge of the following technologies:

- [Terraform](https://www.terraform.io/intro/index.html)
- [Docker](https://www.docker.com/)
- [Microsoft Azure Cloud](https://azure.microsoft.com/)
- [Kubernetes](https://kubernetes.io/docs/concepts/)
 

### Technical Prerequisites

This project supports two options for running Terraform scripts:
- Terraform installed on your local machine
- Using a Docker container to run Terraform. For more information, see [Docker Usage](./docs/user/DockerUsage.md).

Access to an **Azure Subscription** and an [**Identity**](./docs/user/TerraformAzureAuthentication.md) with the *Contributor* role are required.

#### Terraform Requirements:
- [Terraform](https://www.terraform.io/downloads.html) - v1.0.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) - v1.19.9
- [jq](https://stedolan.github.io/jq/) - v1.6
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure) - (optional - useful as an alternative to the Azure Portal) - v2.24.2

#### Docker Requirements:
- [Docker](https://docs.docker.com/get-docker/)

## Deployment Overview

SAS recommends that you complete a workflow similar to the following in order to create and configure your cluster and deploy SAS Viya:
1. Prepare to run viya4-iac-azure by fulfilling the [prerequisites](#prerequisites).
1. Customize and run the Terraform scripts in this project to set up your cluster.
1. Verify that all requirements have been met by checking the [product documentation](https://documentation.sas.com/doc/en/itopssr/v_012/p1pp4c3tx9dxlvn1u3s3keokcz5l.htm).
1. Retrieve the cloud configuration from the [Terraform state file](/docs/user/AdvancedTerraformUsage.md#terraform---state).
1. Complete cluster setup using the tools in the [viya4-deployment](https://github.com/sassoftware/viya4-deployment) project. Use the tfstate file as input for these tools.  
1. Follow the instructions in the [documentation](https://go.documentation.sas.com/doc/en/itopscdc/v_015/itopswlcm/home.htm) to deploy the software.
Start by [obtaining the deployment assets](https://go.documentation.sas.com/doc/en/itopscdc/v_015/dplyml0phy0dkr/n1wwpl7qzfdb5rn1gwfx84tfgj5d.htm).
1. [Deploy the SAS Deployment Operator](https://go.documentation.sas.com/doc/en/itopscdc/v_015/dplyml0phy0dkr/n137b56hwogd7in1onzys95awxqe.htm).
1. [Create the SASDeployment custom resource](https://go.documentation.sas.com/doc/en/itopscdc/v_015/dplyml0phy0dkr/p0nid9gu3x2cvln1pzpcxa68tpom.htm).
1. [Deploy SAS Viya](https://go.documentation.sas.com/doc/en/itopscdc/v_015/dplyml0phy0dkr/p127f6y30iimr6n17x2xe9vlt54q.htm#p0lhaw04t8hfhjn1cn1gadt5gbph).
1. Complete the deployment by making sure that data directories and user private directories are mounted on CAS nodes and on compute server instances.

## Getting Started

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

### Customize Input Values

Running the Terraform script requires modifications variable definitions as input. Many variables do not have default values. Create a file named
`terraform.tfvars` to customize any input variable value documented in the [CONFIG-VARS.md](docs/CONFIG-VARS.md) file. To get started, you can copy one of
the example variable definition files provided in the `./examples` folder. For more information about the variables that are declared in that file,
refer to the [CONFIG-VARS.md](docs/CONFIG-VARS.md) file.

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

## Creating and Managing the Cloud Resources

Create and manage the required cloud resources. Take one of the following steps: 

- run [Terraform](docs/user/TerraformUsage.md) directly on your workstation
- run the [Docker container](docs/user/DockerUsage.md) 

### Troubleshooting

See the [Troubleshooting](./docs/Troubleshooting.md) page for information about possible issues that you might encounter.

## Contributing

> We welcome your contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project.

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
- [Azure AKS](https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html)
