# Public Access

When deploying in Azure resource can be permitted to go over the internet while still being locked down to a specific set of allowed ip address. This is called public mode. It is required when you do not have a vpn or interconnect to Azure to allow for access the various systems and services

## Supported scenarios and requirements when using existing resources

The table below shows the supported scenarios when using existing/bring your own (BYO) resources:

| Scenario|Required variables|Additional requirements|Resources to be created|
| :--- | :--- | :--- | :--- |
| 1. When you have to work with an existing resource group | `resource_group_name` | | Vnet, Subnets, NAT Gateway, Network Security Group, NAT Gateway, Route Table |
| 2. When you want to work with existing resource group, vNet, and subnets | `resource_group_name`, <br>`vnet_name`, <br> `subnet_names` | | Network Security Group, NAT Gateway, Route Table |
| 3. When you want to work with existing resource group, vNet, subnets, and network security group | `resource_group_name`, <br>`vnet_name`, <br>`subnet_names`, <br>`nsg_name` | | Nat Gateway, Route Table |

# Private access

Recommend when you have a vpn or interconnect setup for Azure. In the mode all traffic is private.

## Supported scenarios and requirements when using existing resources

The table below shows the supported scenarios when using existing/bring your own (BYO) resources:

| Scenario|Required variables|Additional requirements|Resources to be created|
| :--- | :--- | :--- | :--- |
| 1. Everything + owner permissions | `resource_group_name`, <br>`vnet_name`, <br>`subnet_names`, <br>`nsg_name` | resource group, vnet, subnets, network security group and route tables must already be setup properly to all direct connection to Azure resources| User Assigned Identity |
| 2. Everything + Use existing UAI and role assignment  | `resource_group_name`, <br>`vnet_name`, <br>`subnet_names`, <br>`nsg_name`, <br>`aks_uai_name` | resource group, vnet, subnets, network security group and route tables must already be setup properly to all direct connection to Azure resources | |
