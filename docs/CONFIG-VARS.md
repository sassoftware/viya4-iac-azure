# Valid Configuration Variables

Supported configuration variables are listed in the tables below.  All variables can also be specified on the command line.  Values specified on the command line will override values in configuration defaults files.

## Table of Contents

- [Valid Configuration Variables](#valid-configuration-variables)
  - [Table of Contents](#table-of-contents)
  - [Required Variables](#required-variables)
    - [Azure Authentication](#azure-authentication)
  - [Admin Access](#admin-access)
  - [Networking](#networking)
    - [Use Existing](#use-existing)
  - [General](#general)
  - [Node Pools](#node-pools)
    - [Default Node Pool](#default-node-pool)
    - [Additional Node Pools](#additional-node-pools)
  - [Storage](#storage)
    - [NFS Server VM (only when `storage_type=standard`)](#nfs-server-vm-only-when-storage_typestandard)
    - [Azure NetApp Files (only when `storage_type=ha`)](#azure-netapp-files-only-when-storage_typeha)
  - [Azure Container Registry (ACR)](#azure-container-registry-acr)
  - [Postgres Servers](#postgres-servers)

Terraform input variables can be set in the following ways:

- Individually, with the [-var command line option](https://www.terraform.io/docs/configuration/variables.html#variables-on-the-command-line).
- In [variable definitions (.tfvars) files](https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files). We recommend using this method for most variables.
- As [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables). We recommend using this method for the variables that configure the [Azure authentication](#azure-authentication).

## Required Variables

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| prefix | A prefix used in the name of all the Azure resources created by this script. | string | | The prefix string must start with a lowercase letter and contain only lowercase alphanumeric characters and dashes (-), but it cannot end with a dash. |
| location | The Azure Region to provision all resources in this script. | string | "eastus" | |

### Azure Authentication

The Terraform process manages Microsoft Azure resources on your behalf. In order to do so, it needs your Azure account information and a user identity with the required permissions.

For details on how to retrieve that information, see [Azure Help Topics](./user/AzureHelpTopics.md).

| Name | Description | Type | Default |
| :--- | ---: | ---: | ---: |
| tenant_id | Your Azure tenant id | string  | |
| subscription_id | Your Azure subscription id | string  | |
| client_id | Your app_id when using a Service Principal | string | "" |
| client_secret | Your client secret when using a Service Principal| string | "" |
| use_msi | Use the Managed Identity of your Azure VM | bool | false |

**NOTE:** Values for `subscription_id` and `tenant_id` are always required. `client_id` and `client_secret` are required when using a Service Principal. `use_msi=true` is required when using an Azure VM Managed Identity.

For recommendations on how to set these variables in your environment, see [Authenticating Terraform to Access Azure](./user/TerraformAzureAuthentication.md).

## Admin Access

By default, the public endpoints of the Azure resources that are being created
are only accessible through authenticated Azure clients
(such as the Azure Portal, the `az` CLI, the Azure Shell, etc.).
To allow access for other administrative client applications (for example `kubectl`, `psql`, `ssh` etc.), you can set Network Security Group (NSG) rules to control access from your source IP addresses.

To do set these permissions as part of this Terraform script, specify ranges of IP addresses in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) with the following variables.

NOTE: When deploying infrastructure into a private network (e.g. a VPN), with no public endpoints, the options documented in this block are not applicable.

NOTE: The script will either create a new NSG, or use an existing NSG, if specified in the [`nsg_name`](#use-existing) variable. 

You can use `default_public_access_cidrs` to set a default range for all created resources. To set different ranges for other resources, define the appropriate variable. Use an empty list `[]` to disallow access explicitly.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| default_public_access_cidrs | IP address ranges allowed to access all created cloud resources | list of strings | | Sets a default for all resources. |
| cluster_endpoint_public_access_cidrs | IP address ranges allowed to access the AKS cluster API | list of strings | | For client admin access to the cluster api (by `kubectl`, for example). Only used with `cluster_api_mode=public`|
| vm_public_access_cidrs | IP address ranges allowed to access the VMs | list of strings | | Opens port 22 for SSH access to the jump server and/or NFS VM by adding Ingress Rule on the NSG. Only used with `create_jump_public_ip=true` or `create_nfs_public_ip=true`   |
| postgres_public_access_cidrs | IP address ranges allowed to access the Azure PostgreSQL Flexible Server | list of strings || Opens port 5432 by adding Ingress Rule on the NSG. Only used when creating postgres instances. |
| acr_public_access_cidrs | IP address ranges allowed to access the ACR instance | list of strings || Only used with `create_container_registry=true` |

**NOTE:** In a SCIM environment, the AzureActiveDirectory service tag must be granted access to port 443/HTTPS for the Ingress IP address. 

## Networking

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | :--- |
| vnet_address_space | Address space for created vnet | string | "192.168.0.0/16" | This variable is ignored when vnet_name is set (AKA bring your own vnet). |
| subnets | Subnets to be created and their settings | map(object) | *check below* | This variable is ignored when subnet_names is set (AKA bring your own subnets). All defined subnets must exist within the vnet address space. |
| cluster_egress_type | The outbound (egress) routing method to be used for this Kubernetes Cluster | string | "loadBalancer" | Possible values: <ul><li>`loadBalancer`<li>`userDefinedRouting`</ul> By default, AKS will create and use a [loadbalancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard) for outgoing connections.<p>Set to `userDefinedRouting` when using your own network [egress](https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype). |


The default values for the `subnets` variable are as follows:

```yaml
{
  aks = {
    "prefixes": ["192.168.0.0/23"],
    "service_endpoints": ["Microsoft.Sql"],
    "private_endpoint_network_policies_enabled": false,
    "private_link_service_network_policies_enabled": false,
    "service_delegations": {},
  }
  misc = {
    "prefixes": ["192.168.2.0/24"],
    "service_endpoints": ["Microsoft.Sql"],
    "private_endpoint_network_policies_enabled": false,
    "private_link_service_network_policies_enabled": false,
    "service_delegations": {},
  }
  ## If using ha storage then the following is also added
  netapp = {
    "prefixes": ["192.168.3.0/24"],
    "service_endpoints": [],
    "private_endpoint_network_policies_enabled": false,
    "private_link_service_network_policies_enabled": false,
    "service_delegations": {
      netapp = {
        "name"    : "Microsoft.Netapp/volumes"
        "actions" : ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}
```

### Use Existing

The variables in the table below can be used to point to existing resources. Refer to the [Bring Your Own Network](./user/BYOnetwork.md) page for information about all supported scenarios for using existing network resources, with additional details and requirements.

Resource Location:

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| resource_group_name | Name of pre-existing resource group to use for all resources created by this utility.   | string | null | If not set, a resource group with the name `<prefix>-rg` will be created. |
| vnet_resource_group_name | Name of a pre-exising resource group that contains any pre-existing resources | string | value of `resource_group_name` | Only required if you use any of `vnet_name`, `subnet_names`, `nsg_name`, or `aks_uai_name`, and if those pre-existing resources are not located in `resource_group_name`. |

Existing Resources:

Note: All of the following resources are expected to be in the Resource Group set by `vnet_resource_group_name`.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| vnet_name | Name of pre-existing vnet | string | null | Only required if deploying into existing vnet. |
| subnet_names | Existing subnets mapped to desired usage. | map(string) | null | Only required if deploying into existing subnets. See the example that follows. |
| nsg_name | Name of pre-existing network security group. | string | null | Only required if deploying into existing NSG. |
| aks_uai_name | Name of existing User Assigned Identity for the cluster | string | null | This Identity will need permissions as listed in [AKS Cluster Identity Permissions](https://docs.microsoft.com/en-us/azure/aks/concepts-identity#aks-cluster-identity-permissions) and [Additional Cluster Identity Permissions](https://docs.microsoft.com/en-us/azure/aks/concepts-identity#additional-cluster-identity-permissions). Alternatively, use can use the [Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) role for this Identity. |

Example for the `subnet_names` variable:

```yaml
subnet_names = {
  ## Required subnets
  'aks': '<my_aks_subnet_name>', 
  'misc': '<my_misc_subnet_name>',

  ## If using ha storage then the following is also required
  'netapp': '<my_netapp_subnet_name>'
}
```

## General

Ubuntu 20.04 LTS is the operating system used on the Jump/NFS servers. Ubuntu creates the `/mnt` location as an ephemeral drive that cannot be used as the root location of the `jump_rwx_filestore_path` variable.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| partner_id | A GUID that is registered with Microsoft to facilitate partner resource usage attribution | string | "5d27f3ae-e49c-4dea-9aa3-b44e4750cd8c" | Defaults to SAS partner GUID. When you deploy this Terraform configuration, Microsoft can identify the installation of SAS software with the deployed Azure resources. Microsoft can then correlate the resources that are used to support the software. Microsoft collects this information to provide the best experiences with their products and to operate their business. The data is collected and governed by Microsoft's privacy policies, located at https://www.microsoft.com/trustcenter. |
| create_static_kubeconfig | Allows the user to create a provider / service account-based kubeconfig file | bool | true | A value of `false` will default to using the cloud provider's mechanism for generating the kubeconfig file. A value of `true` will create a static kubeconfig that uses a `Service Account` and `Cluster Role Binding` to provide credentials. |
| kubernetes_version | The AKS cluster Kubernetes version | string | "1.23.8" | |
| create_jump_vm | Create bastion host | bool | true | |
| create_jump_public_ip | Add public IP address to the jump VM | bool | true | |
| jump_vm_admin | Operating system Admin User for the jump VM | string | "jumpuser" | |
| jump_vm_machine_type | SKU to use for the jump VM | string | "Standard_B2s" | To check for valid types for your subscription, run: `az vm list-skus --resource-type virtualMachines --subscription $subscription --location $location -o table`|
| jump_rwx_filestore_path | File store mount point on jump server | string | "/viya-share" | This location cannot include `/mnt` as its root location. This disk is ephemeral on Ubuntu, which is the operating system being used for the jump/NFS servers. |
| tags | Map of common tags to be placed on all Azure resources created by this script | map | { project_name = "sasviya4", environment = "dev" } | |
| aks_identity | Use UserAssignedIdentity or Service Principal as  [AKS identity](https://docs.microsoft.com/en-us/azure/aks/concepts-identity) | string | "uai" | A value of `uai` wil create a Managed Identity based on the permissions of the authenticated user or use [`AKS_UAI_NAME`](#use-existing), if set. A value of `sp` will use values from [`CLIENT_ID`/`CLIENT_SECRET`](#azure-authentication), if set. |
| ssh_public_key | File name of public ssh key for jump and nfs VM | string | "~/.ssh/id_rsa.pub" | Required with `create_jump_vm=true` or `storage_type=standard` |
| cluster_api_mode | Public or private IP for the cluster api | string | "public" | Valid Values: "public", "private" |
| aks_cluster_sku_tier | Optimizes api server for cost vs availability | string | "Free" | Valid Values:  "Free", "Paid" | 

## Node Pools

### Default Node Pool

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| node_vm_admin | Operating system Admin User for VMs of AKS cluster nodes | string | "azureuser" | |
| default_nodepool_vm_type | Type of the default node pool VMs | string | "Standard_D8s_v4" | |
| default_nodepool_os_disk_size | Disk size for default node pool VMs in GB | number | 128 ||
| default_nodepool_max_pods | Maximum number of pods that can run on each | number | 110 | Changing this forces a new resource to be created. |
| default_nodepool_min_nodes | Minimum and initial number of nodes for the default node pool | number | 1 |  Value must be between 0 and 100. Setting min and max node counts the same disables autoscaling. |
| default_nodepool_max_nodes | Maximum number of nodes for the default node pool| number | 5 | Value must be between 0 and 100. Setting min and max node counts to the same value  disables autoscaling. |
| default_nodepool_availability_zones | Availability Zones for the cluster default node pool | list of strings | ["1"]  | **NOTE:** This value depends on the "location". For example, not all regions have numbered availability zones.|

### Additional Node Pools

Additional node pools can be created separate from the default node pool. This is done with the `node_pools` variable, which is a map of objects. Irrespective of the default values, the following variables are required for each node pool:

| Name | Description | Type | Notes |
| :--- | ---: | ---: | ---: |
| machine_type | Type of the node pool VMs | string | |
| os_disk_size | Disk size for node pool VMs in GB | number | |
| min_nodes | Minimum number of nodes for the node pool | number | Value must be between 0 and 100. Setting min and max node counts to the same value disables autoscaling |
| max_nodes | Maximum number of nodes for the node pool | number | Value must be between 0 and 100. Setting min and max node counts to the same value disables autoscaling |
| max_pods | Maximum number of pods per node | number | Default is 110
| node_taints | Taints for the node pool VMs | list of strings | |
| node_labels | Labels to add to the node pool VMs | map | |

The default values for the `node_pools` variable are as follows:

**Note**: SAS recommends that you maintain a minimum of 1 node in the pool for `compute` workloads. This allocation ensures that compute-related pods have the required images pulled and ready for use in the environment..

```yaml
{
  cas = {
    "machine_type"          = "Standard_E16s_v3"
    "os_disk_size"          = 200
    "min_nodes"             = 0
    "max_nodes"             = 5
    "max_pods"              = 110
    "node_taints"           = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
  },
  compute = {
    "machine_type"          = "Standard_E16s_v3"
    "os_disk_size"          = 200
    "min_nodes"             = 1
    "max_nodes"             = 5
    "max_pods"              = 110
    "node_taints"           = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
  },
  stateless = {
    "machine_type"          = "Standard_D16s_v3"
    "os_disk_size"          = 200
    "min_nodes"             = 0
    "max_nodes"             = 5
    "max_pods"              = 110
    "node_taints"           = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
  },
  stateful = {
    "machine_type"          = "Standard_D8s_v3"
    "os_disk_size"          = 200
    "min_nodes"             = 0
    "max_nodes"             = 3
    "max_pods"              = 110
    "node_taints"           = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
  }
}
```

In addition, you can control the placement for the additional node pools using the following values:

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| node_pools_availability_zone | Availability Zone for the additional node pools and the NFS VM, for `storage_type="standard"'| string | "1" | The possible values depend on the region set in the "location" variable. |
| node_pools_proximity_placement | Co-locates all node pool VMs for improved application performance. | bool | false | Selecting proximity placement imposes an additional constraint on VM creation and can lead to more frequent denials of VM allocation requests. We recommend that you set `node_pools_availability_zone=""` and allocate all required resources at one time by setting `min_nodes` and `max_nodes` to the same value for all node pools.  Additional information: [Proximity Group Placement](./user/ProximityPlacementGroup.md). |

## Storage

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| storage_type | Type of Storage. Valid Values: "standard", "ha"  | string | "standard" | "standard" creates NFS server VM, "ha" creates Azure Netapp Files|

### NFS Server VM (only when `storage_type=standard`)

When `storage_type=standard`, a NFS Server VM is created, only when these variables are applicable.

**NOTE:** When `node_pools_proximity_placement=true` is set, the NFS VM will be co-located in the proximity group with the additional node pool VMs.

**NOTE:** The 128 default is in GB. With a RAID5 configuration, the default is 4 disks, so [the defaults would yield (N-1) x S(min)](https://superuser.com/questions/272990/how-to-calculate-the-final-raid-size-of-a-raid-5-array), or (4-1) x 128GB = ~384 GB.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_nfs_public_ip | Add public ip to the NFS server VM | bool | false | |
| nfs_vm_admin | OS Admin User for the NFS server VM | string | "nfsuser" | |
| nfs_vm_machine_type | SKU to use for NFS server VM | string | "Standard_D8s_v4" | To check for valid types for your subscription, run: `az vm list-skus --resource-type virtualMachines --subscription $subscription --location $location -o table`|
| nfs_vm_zone | Zone in which NFS server VM should be created | string | null | |
| nfs_raid_disk_type | Managed disk types | string | "Standard_LRS" | Supported values: Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS. When using `UltraSSD_LRS`, `nfs_vm_zone` and `nfs_raid_disk_zone` must be specified. See the [Azure documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-enable-ultra-ssd) for limitations on Availability Zones and VM types. |
| nfs_raid_disk_size | Size in Gb for each disk of the RAID5 cluster on the NFS server VM | number | 128 | |
| nfs_raid_disk_zone | The Availability Zone in which the Managed Disk should be located. Changing this property forces a new resource to be created. | string | null | |

### Azure NetApp Files (only when `storage_type=ha`)

When `storage_type=ha` (high availability), [Microsoft Azure NetApp Files](https://azure.microsoft.com/en-us/services/netapp/) service is created, only when these variables are applicable. Before using this storage option, read about how to [Register for Azure NetApp Files](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-register) to ensure your Azure Subscription has been granted access to the service.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| netapp_service_level | The target performance level of the file system. Valid values include Premium, Standard, or Ultra. | string | "Premium" | |
| netapp_size_in_tb | Provisioned size of the pool in TB. Value must be between 4 and 500 | number | 4 | |
| netapp_protocols | The target volume protocol expressed as a list. Supported single value include CIFS, NFSv3, or NFSv4.1. If argument is not defined, it defaults to NFSv3. Changing this forces a new resource to be created and data will be lost. | list of strings | ["NFSv3"] | |
| netapp_volume_path |A unique file path for the volume. Used when creating mount targets. Changing this forces a new resource to be created. | string | "export" | |
| netapp_network_features |Indicates which network feature to use, accepted values are `Basic` or `Standard`, it defaults to `Basic` if not defined. | string | "Basic" | This is a feature in public preview. For more information about it and how to register, please refer to [Configure network features for an Azure NetApp Files volume](https://docs.microsoft.com/en-us/azure/azure-netapp-files/configure-network-features)|

## Azure Container Registry (ACR)

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_container_registry| Create container registry instance | bool | false | |
| container_registry_sku | Service tier for the registry | string | "Standard" | Possible values: "Basic", "Standard", "Premium" |
| container_registry_admin_enabled | Enables the admin user | bool | false | |
| container_registry_geo_replica_locs | List of Azure locations where the container registry should be geo-replicated. | list of strings | null | This is only supported when `container_registry_sku` is set to `"Premium"`. |

## Postgres Servers

When setting up ***external database servers***, you must provide information about those servers in the `postgres_servers` variable block. Each entry in the variable block represents a ***single database server***.

This code only configures database servers. No databases are created during the infrastructure setup.

The variable has the following format:

```terraform
postgres_servers = {
  default = {},
  ...
}
```

**NOTE**: The `default = {}` elements is always required when creating external databases. This is the systems default database server.

Each server element, like `foo = {}`, can contain none, some, or all of the parameters listed below:

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| sku_name| The SKU Name for the PostgreSQL Flexible Server | string | "GP_Standard_D16s_v3" | The name pattern is the SKU, followed by the tier + family + cores (e.g. B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3).|
| storage_mb | The max storage allowed for the PostgreSQL Flexible Server | number | 51200 | Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432. |
| backup_retention_days | Backup retention days for the PostgreSQL Flexible server | number | 7 | Supported values are between 7 and 35 days. |
| geo_redundant_backup_enabled | Enable Geo-redundant or not for server backup | bool | false | Not supported for the basic tier. |
| administrator_login | The Administrator Login for the PostgreSQL Flexible Server. Changing this forces a new resource to be created. | string | "pgadmin" | The admin login name cannot be azure_superuser, azure_pg_admin, admin, administrator, root, guest, or public. It cannot start with pg_. See: [Microsoft Quickstart Server Database](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/quickstart-create-server-portal) |
| administrator_password | The Password associated with the administrator_login for the PostgreSQL Flexible Server | string | "my$up3rS3cretPassw0rd" | The password must contain between 8 and 128 characters and must contain characters from three of the following categories: English uppercase letters, English lowercase letters, numbers (0 through 9), and non-alphanumeric characters (!, $, #, %, etc.). |
| server_version | The version of the PostgreSQL Flexible server instance | string | "13" | Refer to the [Viya 4 Administration Guide](https://go.documentation.sas.com/doc/en/sasadmincdc/default/itopssr/p05lfgkwib3zxbn1t6nyihexp12n.htm?fromDefault=#p1wq8ouke3c6ixn1la636df9oa1u) for the supported versions of PostgreSQL for SAS Viya. |
| ssl_enforcement_enabled | Enforce SSL on connection to the Azure Database for PostgreSQL Flexible server instance | bool | true | |
| postgresql_configurations | Sets a PostgreSQL Configuration value on a Azure PostgreSQL Flexible Server | list(object) | [] | More details can be found [here](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/howto-configure-server-parameters-using-cli) |

Here is a sample of the `postgres_servers` variable with the `default` entry only overriding the `administrator_password` parameter and the `cps` entry overriding all of the parameters:

```terraform
postgres_servers = {
  default = {
    administrator_password       = "D0ntL00kTh1sWay"
  },
  another_server = {
    sku_name                     = "GP_Standard_D16s_v3"
    storage_mb                   = 65536
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false
    administrator_login          = "pgadmin"
    administrator_password       = "1tsAB3aut1fulDay"
    server_version               = "13"
    ssl_enforcement_enabled      = true
    postgresql_configurations    = [
       {
         name  = "azure.extensions"
         value = "PLPGSQL,LTREE"
       }
      ]
  }
}
```
