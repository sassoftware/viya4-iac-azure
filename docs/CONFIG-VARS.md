# List of valid configuration variables

Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Required Variables](#required-variables)
  - [Application](#application)
  - [Azure Authentication](#azure-authentication)
- [Admin Access](#admin-access)
- [General](#general)
- [Nodepools](#nodepools)
  - [Default Nodepool](#default-nodepool)
  - [Additional Nodepools](#additional-nodepools)
- [Storage](#storage)
  - [storage_type=standard - nfs server VM](#storage_typestandard---nfs-server-vm)
  - [storage_type=ha - Azure NetApp](#storage_typeha---azure-netapp)
- [Azure Container Registry (ACR)](#azure-container-registry-acr)
- [Postgres](#postgres)

Terraform input variables can be set in the following ways:

- Individually, with the [-var command line option](https://www.terraform.io/docs/configuration/variables.html#variables-on-the-command-line).
- In [variable definitions (.tfvars) files](https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files). We recommend this way for most variables.
- As [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables). We recommend this way for the variables that set the [Azure authentication](#azure-authentication).

## Required Variables

### Application

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| prefix | A prefix used in the name of all the Azure resources created by this script. | string | | The prefix string must start with a lowercase letter and contain only alphanumeric characters and dashes (-), but cannot end with a dash. |
| location | The Azure Region to provision all resources in this script | string | "East US" | |
| tags | Map of common tags to be placed on all Azure resources created by this script | map | { project_name = "sasviya4", environment = "dev" } | |

### Azure Authentication

The Terraform process manages Azure resources on your behalf. In order to do so, it needs to know your Azure account information, and a user identity with the required permissions.

Find details on how to retrieve that information under [Azure Help Topics](./user/AzureHelpTopics.md).

| Name | Description | Type | Default |
| :--- | ---: | ---: | ---: |
| tenant_id | your Azure tenant id | string  |
| subscription_id | your Azure subscription id | string  |
| client_id | your app_id when using a Service Principal | string | "" |
| client_secret | your client secret when using a Service Principal| string | "" |
| use_msi | use the Managed Identity of your Azure VM | bool | false |

NOTE: `subscription_id` and `tenant_id` are always required. `client_id` and `client_secret` are required when using a Service Principal. `use_msi=true` is required when using an Azure VM Managed Identitty.

For recommendation on how to set these variables in your environment, see [Authenticating Terraform to access Azure](./user/TerraformAzureAuthentication.md).

## Admin Access

By default, the API of the Azure resources that are being created are only accessible through authenticated Azure clients (e.g. the Azure Portal, the `az` CLI, the Azure Shell, etc.)
To allow access for other administrative client applications (for example `kubectl`, `psql`, etc.), you want to open up the Azure firewall to allow access from your source IPs.
To do this, specify ranges of IP in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing).
Contact your Network System Administrator to find the public CIDR range of your network.

You can use `default_public_access_cidrs` to set a default range for all created resources. To set different ranges for other resources, define the appropriate variable. Use and empty list `[]` to disallow access explicitly.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| default_public_access_cidrs | IP Ranges allowed to access all created cloud resources | list of strings | | Use to to set a default for all Resources |
| cluster_endpoint_public_access_cidrs | IP Ranges allowed to access the AKS cluster api | list of strings | | for client admin access to the cluster, e.g. with `kubectl` |
| vm_public_access_cidrs | IP Ranges allowed to access the VMs | list of strings | | opens port 22 for SSH access to the jump and/or nfs VM |
| postgres_access_cidrs | IP Ranges allowed to access the Azure PostgreSQL Server | list of strings |||
| acr_access_cidrs | IP Ranges allowed to access the ACR instance | list of strings |||

## General

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| kubernetes_version | The AKS cluster K8S version | string | "1.18.8" | |
| ssh_public_key | Name of file with public ssh key for VMs | string |"" | If no key is given, a keypair will be generated and output into the `ssh_public_key` and `ssh_private_key` output variables |
| create_jump_vm | Create bastion host | bool | false for storage_type == "dev", otherwise true| |
| create_jump_public_ip | Add public ip to jump VM | bool | true | |
| jump_vm_admin | OS Admin User for the Jump VM | string | "jumpuser" | |

## Nodepools

### Default Nodepool

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| node_vm_admin | OS Admin User for VMs of AKS Cluster nodes | string | "azureuser" | |
| default_nodepool_vm_type | Type of the default nodepool VMs | string | "Standard_D4_v2" | |
| default_nodepool_os_disk_size | Disk size for default nodepool VMs in GB | number | 128 ||
| default_nodepool_max_pods | Maximum number of pods that can run on each | number | 110 | Changing this forces a new resource to be created |
| default_nodepool_min_nodes | Minimum and initial number of nodes for the default nodepool | number | 1 |  Value must be between 0 and 100. Setting min and max node counts the same disables autoscaling  |
| default_nodepool_max_nodes | Maximum number of nodes for the default nodepoo| number | 5 | Value must be between 0 and 100. Setting min and max node counts the same disables autoscaling |
| default_nodepool_availability_zones | Availability Zones for the cluster default nodepool | list of strings | ["1"]  | Note: This value depends on the "location". For example, not all regions have numbered availability zones|

### Additional Nodepools

Additional node pools can be created separate from the default nodepool. This is done with the `node_pools` variable which is a map of objects. Each nodepool requires the following variables
| Name | Description | Type | Notes |
| :--- | ---: | ---: | ---: |
| machine_type | Type of the nodepool VMs | string | |
| os_disk_size | Disk size for nodepool VMs in GB | number | |
| min_nodes | Minimum number of nodes for the nodepool | number | Value must be between 0 and 100. Setting min and max node counts the same disables autoscaling |
| max_nodes | Maximum number of nodes for the nodepool | number | Value must be between 0 and 100. Setting min and max node counts the same disables autoscaling |
| max_pods | Maximum number of pods per node | number | Default is 110
| node_taints | Taints for the nodepool VMs | list of strings | |
| node_labels | Labels to add to the nodepool VMs | map | |


The default values for the `node_pools` variable are:

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
    "min_nodes"             = 0
    "max_nodes"             = 5
    "max_pods"              = 110
    "node_taints"           = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
  },
  connect = {
    "machine_type"          = "Standard_E16s_v3"
    "os_disk_size"          = 200
    "min_nodes"             = 0
    "max_nodes"             = 5
    "max_pods"              = 110
    "node_taints"           = ["workload.sas.com/class=connect:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "connect"
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

In addition, you can control the placement for the additional nodepools using

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| node_pools_availability_zone | Availability Zone for the additional nodepools and the NFS VM, for `storage_type="standard"'| string | "1" | The possible values depend on the region set in the "location" variable. |
| node_pools_proximity_placement | Co-locates all node pool VMs for improved application performance. | bool | false | Selecting proximity placement imposes an additional constraint on VM creation and can lead to more frequent denials of VM allocation requests. We recommend to set `node_pools_availability_zone=""` and allocate all required resources at one time by setting `min_nodes` and `max_nodes` to the same value for all node pools.  Additional Information: [Proximity Group Placement](./user/ProximityPlacementGroup.md) |


## Storage

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| storage_type | Type of Storage. Valid Values: "dev", "standard", "ha"  | string | "dev" | "dev" creates AzureFile, "standard" creates NFS server VM, "ha" creates Azure Netapp Files|

### storage_type=standard - nfs server VM

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_nfs_public_ip | Add public ip to the NFS server VM | bool | false | The NFS server VM is only created when storage_type="standard" |
| nfs_vm_admin | OS Admin User for the NFS server VM | string | "nfsuser" | The NFS server VM is only created when storage_type="standard" |
| nfs_raid_disk_size | Size in Gb for each disk of the RAID5 cluster on the NFS server VM | number | 128 | The NFS server VM is only created when storage_type="standard" |

Note: When `node_pools_proximity_placement=true` is set, the NFS VM will be co-located in the proximity group with the additional node pool VMs.
Note: The 128 default is in GB, so with a RAID5, the default is 4 disks, [so the defaults would yield (N-1) x S(min)](https://superuser.com/questions/272990/how-to-calculate-the-final-raid-size-of-a-raid-5-array), or (4-1) x 128GB = ~384GB.

### storage_type=ha - Azure NetApp

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_netapp | create Azure NetApp Files | bool | false | |
| netapp_service_level | The target performance level of the file system. Valid values include Premium, Standard, or Ultra | string | "Premium" | |
| netapp_size_in_tb | Provisioned size of the pool in TB. Value must be between 4 and 500 | number | 4 | |
| netapp_protocols | The target volume protocol expressed as a list. Supported single value include CIFS, NFSv3, or NFSv4.1. If argument is not defined it will default to NFSv3. Changing this forces a new resource to be created and data will be lost. | list of strings | ["NFSv3"] | |
| netapp_volume_path |A unique file path for the volume. Used when creating mount targets. Changing this forces a new resource to be created. | string | "export" | |

## Azure Container Registry (ACR)

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_container_registry| Create container registry instance | bool | false | |
| container_registry_sku | Service tier for the registry | string | "Standard" | Possible values: "Basic", "Standard", "Premium" |
| container_registry_admin_enabled | Enables the admin user | bool | false | |
| container_registry_geo_replica_locs |   list of Azure locations where the container registry should be geo-replicated.| list of strings | [] | |

## Postgres

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_postgres | Create an Azure Database for PostgreSQL server instance | bool | false | |
| postgres_sku_name| The SKU Name for the PostgreSQL Server | string | "GP_Gen5_32" | The name pattern is the SKU, followed by the tier + family + cores (e.g. B_Gen4_1, GP_Gen5_4).|
| postgres_storage_mb | Max storage allowed for the PostgreSQL server | number | 51200 | Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs |
| postgres_backup_retention_days | Backup retention days for the PostgreSQL server | number | 7 | Supported values are between 7 and 35 days. |
| postgres_geo_redundant_backup_enabled | Enable Geo-redundant or not for server backup | bool | false | Not supported for the basic tier. |
| postgres_administrator_login | The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created. | string | "pgadmin" | The admin login name cannot be azure_superuser, azure_pg_admin, admin, administrator, root, guest, or public. It cannot start with pg_. See: [Microsoft Quickstart Server Database](https://docs.microsoft.com/en-us/azure/postgresql/quickstart-create-server-database-portal) |
| postgres_administrator_password | The Password associated with the postgres_administrator_login for the PostgreSQL Server | string | | The password must contain between 8 and 128 characters and must contain characters from three of the following categories: English uppercase letters, English lowercase letters, numbers (0 through 9), and non-alphanumeric characters (!, $, #, %, etc.). |
| postgres_server_version | The version of the Azure Database for PostgreSQL server instance. Valid values are "9.5", "9.6", "10.0", and "11". Changing this forces a new resource to be created.| string | "11" | |
| postgres_ssl_enforcement_enabled | Enforce SSL on connection to the Azure Database for PostgreSQL server instance | bool | true | |
| postgres_db_names | List of names for databases to create for the Azure Database for PostgreSQL server instance. Each name needs to be a valid PostgreSQL identified. Changes this forces a new resource to be created. | list of strings | [] | |
| postgres_db_charset | The Charset for the PostgreSQL Database. Needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created. | string | "UTF8" | |
| postgres_db_collation | The Collation for the PostgreSQL Database. Needs to be a valid PostgreSQL Collation. Changing this forces a new resource to be created. |string| "English_United States.1252" | |
| postgres_configurations | Configurations to enable on the PostgreSQL Database server instance | map | {} | |
