# Supported Scenarios and Requirements for Using Existing Network Resources

You have the option to use existing network resources with SAS Viya 4 Terraform scripts. The table below lists the components you can provide.

**NOTE:** We refer to the use of existing resources as "bring your own" or "BYO" resources.

XXXX NOTE: the permissions required for the Identity or Service Principal that runs the terraform script vary, depending on which components you provide. 

## Resource Location

By default, this script will create a Resource Group named `<prefix>-rg` for all the resources created directly by the Terraform script. You can bring your own resource group using the `resource_group_name` input variable.

**NOTE:** AKS itself always creates a [Secondary Resource Group](https://docs.microsoft.com/en-us/azure/aks/faq#why-are-two-resource-groups-created-with-aks) for its additional resources.

Any BYO resources you bring are expected to be in the `vnet_resource_group_name`. If you do not specify a `vnet_resource_group_name`, the BYO resources are expected to be in `resource_group_name`.  

## Variables

| Component |Required Variable|Additional Requirements|If not Provided|
| :--- | :--- | :--- | :--- |
| Use an existing VNET | `vnet_name` | <ul><li>the VNET IPv4 address space(s) must encompass the subnet cidr ranges as set by the [`subnets` variable](../CONFIG-VARS.md#networking) |creates a VNET with the primary address space as set in the [`vnet_address_space` variable](../CONFIG-VARS.md#networking).|
| Use VNET with Subnets | `subnet_names` | <ul><li>a VNET set with the `vnet_name` variable.<li>use the subnet attributes as listed in the default value for the [`subnets` variable](../CONFIG-VARS.md#networking) <li>you also need to have a [Route Table and a Route to the aks subnet](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#bring-your-own-subnet-and-route-table-with-kubenet) | creates subnets as set in the [`subnets` variable](../CONFIG-VARS.md#networking), as well as a Route Table for the aks subnet. Note that [AKS will modify the Route Table](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#bring-your-own-subnet-and-route-table-with-kubenet) ||
| NAT Gateway | `nat_gateway_name`| <ul><li>VNET and subnets set with the `vnet_name` and `subnet_names` variables | creates a NAT Gateway with a Route to the aks subnet.  |
| Network Security Group | `nsg_name` | see [below](#network-security-group) for more detail | creates a Network Security Group for external access |
| AKS Idenity | `aks_uai` | | create UAI or use Service Principal, as set by the [`aks_identity`](../CONFIG-VARS.md#general) varable |


## Network Security Group

By default, this script creates a Network Security Group and adds firewall rules 
to allow external external access to the Jump/NFS VMs and Postgres, as set by the 
[`vm_public_access_cidrs`/`postgres_public_access_cidrs`](../CONFIG-VARS.md#admin-access) variables.

You can provide your own Network Security Group with the `nsg_name` variable. 
The terraform script will try to add firewall rules to that security group for any 
values set by the [`vm_public_access_cidrs`/`postgres_public_access_cidrs`](../CONFIG-VARS.md#admin-access) variables.

## Additional Information

To plan your subnet CIDR blocks for IP address ranges, here are some helpful links:
- https://network00.com/NetworkTools/IPv4AddressPlanner/
- https://www.davidc.net/sites/default/subnets/subnets.html
