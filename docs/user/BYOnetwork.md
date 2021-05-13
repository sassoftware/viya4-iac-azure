## Supported scenarios and requirements when using existing network resources

The table below shows the supported scenarios when using existing/bring your own(BYO) network resources:

| Scenario|Required variables|Additional requirements|Resources to be created|
| :--- | :--- | :--- | :--- |
| 1. When you have to work with an existing `Resource Group` | `resource_group_name` | Only required if deploying into existing resource group |  |
| 2. When you have to work with an existing `Virtual Network` | `vnet_name` | Only required if deploying into existing vnet |  |
| 3. When you have to work with an existing `Network Security Group` | `nsg_name` | Only required if deploying into existing nsg |  |
| 4. When you have to work with existing `Subnets` | `subnet_names` | Only required if deploying into existing subnets. When this option is choosen you must provide **ALL** required subnets. These may include: `aks` / `misc` / `netapp` |  | 

When creating your BYO Network resources you should consult with your Network Administrator.

Azure docs for reference:
- [Resource Group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal/)
- [Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/quick-create-portal/)
- [Network Security Group](https://docs.microsoft.com/en-us/azure/virtual-network/manage-network-security-group/)
- [Subnets](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-subnet/)

To plan your Subnet CIDR blocks for IP ranges, here are some helpful links:
- https://network00.com/NetworkTools/IPv4AddressPlanner/
- https://www.davidc.net/sites/default/subnets/subnets.html
