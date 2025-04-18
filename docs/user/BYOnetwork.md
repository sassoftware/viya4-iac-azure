# Supported Scenarios and Requirements for Using Existing Network Resources

You have the option to use existing network resources with SAS Viya 4 Terraform scripts. The table below lists the components you can provide.

**NOTE:** We refer to the use of existing resources as "bring your own" or "BYO" resources.

**NOTE:** The minimal permissions required for the Identity or Service Principal that runs the Terraform script vary, depending on which components you provide. For all scenarios, the [Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) Role will work.

## Resource Location

By default, the Terraform script will create a Resource Group named `<prefix>-rg` for all the resources created directly by the script. You can bring your own resource group using the `resource_group_name` input variable.

**NOTE:** AKS itself always creates a [Secondary Resource Group](https://docs.microsoft.com/en-us/azure/aks/faq#why-are-two-resource-groups-created-with-aks) for its additional resources.

Any BYO resources you bring are expected to be in the `vnet_resource_group_name`. If you do not specify a `vnet_resource_group_name`, the BYO resources are expected to be in `resource_group_name`.

## Scenarios

| Scenario |Required Variable|Additional Requirements|If not Provided|
| :--- | :--- | :--- | :--- |
| Use an existing VNET | `vnet_name` | <ul><li>the VNET IPv4 address space(s) must encompass the subnet cidr ranges as set by the [`subnets` variable](../CONFIG-VARS.md#networking) |creates a VNET with the primary address space as set in the [`vnet_address_space` variable](../CONFIG-VARS.md#networking).|
| Use VNET with Subnets | `subnet_names` | <ul><li>a VNET set with the `vnet_name` variable.<li>the subnets you bring should have the same attribuites as the default [`subnets` variable](../CONFIG-VARS.md#networking) <li>ensure the subnets have access to requisite Microsoft services (per deployment elections) through service endpoints.  If electing for an external Postgres database, create a service endpoint for `Microsoft.Sql` in both the `aks` & `misc` subnets <li>you also need to have a [Route Table and a Route to the aks subnet](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#bring-your-own-subnet-and-route-table-with-kubenet) <li>an [AKS Cluster identity](#cluster-identity) with write permissions to the aks subnet and route table | creates subnets as set in the [`subnets` variable](../CONFIG-VARS.md#networking), as well as a Route Table for the AKS subnet. Note that [AKS will modify the Route Table](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet#bring-your-own-subnet-and-route-table-with-kubenet).  |
| Provide Network Egress| `cluster_egress_type="userDefinedRouting"` | <ul><li>A VNET and subnets set with the `vnet_name` and `subnet_names` variables. <li>Network  [egress](https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype) needs to be defined (with NAT, Azure Firewall or similar) | AKS will create and use a [loadbalancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard) for outgoing traffic.|

## Network Security Group

By default, this script creates a Network Security Group and adds firewall rules
to allow external access to the Jump/NFS VMs and Postgres, as set by the
[`vm_public_access_cidrs`/`postgres_public_access_cidrs`](../CONFIG-VARS.md#admin-access) variables.

You can provide your own Network Security Group with the `nsg_name` variable.
The Terraform script will try to add firewall rules to that security group for any
values set by the [`vm_public_access_cidrs`/`postgres_public_access_cidrs`](../CONFIG-VARS.md#admin-access) variables.

## Cluster Identity

When creating an AKS cluster, Azure associates an Identity with the cluster. Any resources created on behalf of the cluster (e.g. VMs for the Node Pools etc.) will use the permissions associated with that Identity.
By default, an Identity with the same permissions as the [Identity used for  authenticating to the Terraform script](TerraformAzureAuthentication.md) will be used. However, the new Identity may not have the same scope as the authenticating Identity. You can choose to use the Service Principal directly (if used), or bring your own User Assigned Identity, depending on the setting of the  [`aks_identity`](../CONFIG-VARS.md#general) variable. 

When providing your own networking, the AKS cluster identity will need write access to the aks subnet and the associated routing table. If an alternate identity is not provided then the resulting identity will have permissions assigned to the networking components directly (by default Network Contributor). This will require your authenticating identity to have [Permissions for Assigning Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal#prerequisites).

See [AKS Cluster Identity Permissions](https://docs.microsoft.com/en-us/azure/aks/concepts-identity#aks-cluster-identity-permissions) and [Additional Cluster Identity Permissions](https://docs.microsoft.com/en-us/azure/aks/concepts-identity#additional-cluster-identity-permissions) for details.

## Additional Information

To plan your subnet CIDR blocks for IP address ranges, here are some helpful links:
- https://network00.com/NetworkTools/IPv4AddressPlanner/
- https://www.davidc.net/sites/default/subnets/subnets.html
