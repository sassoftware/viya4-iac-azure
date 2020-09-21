# List of valid configuration variables
Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

## Table of Contents

* [Required Variables](#required-variables)
* [Required Variables for Azure Authentication](#required-variables-for-azure-authentication)
* [General](#general)
* [Nodepools](#nodepools)
   + [Default Nodepool](#default-nodepool)
   + [CAS Nodepool](#cas-nodepool)
   + [Compute Nodepool](#compute-nodepool)
   + [Connect Nodepool](#connect-nodepool)
   + [Stateless Nodepool](#stateless-nodepool)
   + [Stateful Nodepool](#stateful-nodepool)
* [Storage](#storage)
   + [storage_type=dev - azurefile](#storage-type-dev---azurefile)
   + [storage_type=standard - nfs server VM](#storage-type-standard---nfs-server-vm)
   + [storage_type=ha - Azure NetApp](#storage-type-ha---azure-netapp)
* [Azure Container Registry (ACR)](#azure-container-registry--acr-)
* [Postgres](#postgres)

Terraform input variables can be set in the following ways:
- Individually, with the [-var command line option](https://www.terraform.io/docs/configuration/variables.html#variables-on-the-command-line).
- In [variable definitions (.tfvars) files](https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files). We recommend this way for most variables.
- As [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables). We recommend this way for the variables that set the [Azure authentication](#required-variables-for-azure-authentication).

## Required Variables
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: | 
| prefix | A prefix used in the name of all the Azure resources created by this script. | string | | The prefix string must start with a lowercase letter and contain only alphanumeric characters and dashes (-), but cannot end with a dash. |
| location | The Azure Region to provision all resources in this script | string | "East US" | |
| cluster_endpoint_public_access_cidrs | IP Ranges allowed to access the cloud resources | list of strings | | Example: ["55.55.55.55/32", "66.66.0.0/16"]
| tags | Map of common tags to be placed on all Azure resources created by this script | map | { project_name = "sasviya4", environment = "dev" } | |

## Required Variables for Azure Authentication 
The Terraform process manages Azure resources on your behalf. In order to do so, it needs to know your Azure account information, and a user identity with the required permissons. 

Find details on how to retrieve that information under [Azure Help Topics](./docs/user/AzureHelpTopics.md).

| Name | Description | Type | Default | 
| :--- | ---: | ---: | ---: | 
| tenant_id | your Azure tenant id | string  | 
| subscription_id | your Azure subscription id | string  | 
| client_id | your Azure Service Principal id | string | 
| client_secret | your Azure Service Principal secret | string |  


You can set these variables in your `*.tfvars` file. But since they contain sensitive information, we recommend to use Terraform environment variables instead.

Run these commands to initialize the environment for the project. These commands will need to be run and pulled  into your environment each time you start a new session to use this repo and terraform.

```
# export needed ids and secrets
export TF_VAR_subscription_id=[SUBSCRIPTION_ID]
export TF_VAR_tenant_id=[TENANT_ID]
export TF_VAR_client_id=[SP_APPID]
export TF_VAR_client_secret=[SP_PASSWD]
```
**TIP:** These commands can be stored in a file outside of this repo in a secure file. \
Use your favorite editor, take the content above and save it to a file called: `$HOME/.azure_creds.sh` \
Now each time you need these values you can do the following:

```
source $HOME/.azure_creds.sh
```

This will pull in those values into your current terminal session. Any terraform commands submitted in that session will use those values.



## General 
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: | 
| kubernetes_version | The AKS cluster K8S version | string | "1.18.8" | |
| ssh_public_key | Public ssh key for VMs | string | | |

## Nodepools
### Default Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| node_vm_admin | OS Admin User for VMs of AKS Cluster nodes | string | "azureuser" | |
| default_nodepool_nodecount | Number of node in the default nodepool | number | 2 | The value must be between 1 and 100 and between `default_nodepool_min_nodes` and `default_nodepool_max_nodes`|
| default_nodepool_vm_type | Type of the default nodepool VMs | string | "Standard_D4_v2" | |
| default_nodepool_auto_scaling | Enable autoscaling for the AKS cluster default nodepool | bool | false | see https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler |
| default_nodepool_os_disk_size | Disk size for default nodepool VMs in GB | number | 128 ||
| default_nodepool_max_pods | Maximum number of pods that can run on each | number | 110 | Changing this forces a new resource to be created |
| default_nodepool_max_nodes | Maximum number of nodes for the default nodepool when using autoscaling | number | 5 | Required, when `default_nodepool_auto_scaling=true`, value must be between 1 and 100 |
| default_nodepool_min_nodes | Minimum number of nodes for the default nodepool when using autoscaling | number | 1 | Required, when `default_nodepool_auto_scaling=true`, value must be between 1 and 100 |
| default_nodepool_availability_zones | Availability Zones for the cluster default nodepool | list of strings | []  | Note: This value depends on the "location". For example, not all regions have numbered availability zones|
### CAS Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_cas_nodepool | Create CAS nodepool | bool | true | |
| cas_nodepool_vm_type | Type of the CAS nodepool VMs | string | "Standard_E16s_v3" | |
| cas_nodepool_os_disk_size | Disk size for CAS nodepool VMs in GB | number | 200 | |
| cas_nodepool_node_count| Number of CAS nodepool VMs | number | 1 | The value must be between 1 and 100 and between `cas_nodepool_min_nodes` and `cas_nodepool_max_nodes` |
| cas_nodepool_auto_scaling | Enable autoscaling for the CAS nodepool | bool | true | | |
| cas_nodepool_max_nodes | Maximum number of nodes for the CAS nodepool when using autoscaling | number | 5 | Required, when `cas_nodepool_auto_scaling=true`, specified value must be between 1 and 100|
| cas_nodepool_min_nodes | Minimum number of nodes for the CAS nodepool when using autoscaling | number | 1 | Required, when `cas_nodepool_auto_scaling=true`, specified value must be between 1 and 100|
| cas_nodepool_taints | Taints for the CAS nodepool VMs | list of strings | ["workload.sas.com/class=cas:NoSchedule"] | |
| cas_nodepool_labels | Labels to add to the CAS nodepool VMs | map | {"workload.sas.com/class" = "cas"} | |
| cas_nodepool_availability_zones | Availability Zones for CAS nodepool | list of strings | [] | Note: This value depends on the "location". For example, not all regions have numbered availability zones|
### Compute Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_compute_nodepool | Create Compute nodepool | bool | true | false | |
| compute_nodepool_vm_type | Type of the Compute nodepool VMs | string | "Standard_E16s_v3" | |
| compute_nodepool_os_disk_size | Disk size for Compute nodepool VMs in GB | number | 200 | |
| compute_nodepool_node_count| Number of Compute nodepool VMs | number | 1 | The value must be between 1 and 100 and between `compute_nodepool_min_nodes` and `compute_nodepool_max_nodes` |
| compute_nodepool_auto_scaling | Enable autoscaling for the Compute nodepool | bool | true | | |
| compute_nodepool_max_nodes | Maximum number of nodes for the Compute nodepool when using autoscaling | number | 5 | Required, when `compute_nodepool_auto_scaling=true`, specified value must be between 1 and 100 |
| compute_nodepool_min_nodes | Minimum number of nodes for the Compute nodepool when using autoscaling | number | 1 | Required, when `compute_nodepool_auto_scaling=true`, specified value must be between 1 and 100 |
| compute_nodepool_taints | Taints for the Compute nodepool VMs | list of strings | ["workload.sas.com/class=compute:NoSchedule"] | |
| compute_nodepool_labels | Labels to add to the Compute nodepool VMs | map | {"workload.sas.com/class" = "compute"  "launcher.sas.com/prepullImage" = "sas-programming-environment" }  | |
| compute_nodepool_availability_zones | Availability Zones for the Compute nodepool | list of strings | [] | Note: This value depends on the "location". For example, not all regions have numbered availability zones|

### Connect Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_connect_nodepool | Create Connect nodepool | bool | true | false | |
| connect_nodepool_vm_type | Type of the Connect nodepool VMs | string | "Standard_E16s_v3" | |
| connect_nodepool_os_disk_size | Disk size for Connect nodepool VMs in GB | number | 200 | |
| connect_nodepool_node_count| Number of Connect nodepool VMs | number | 1 | The value must be between 1 and 100 and between `connect_nodepool_min_nodes` and `compute_nodepool_max_nodes`|
| connect_nodepool_auto_scaling | Enable autoscaling for the Connect nodepool | bool | true | |
| connect_nodepool_max_nodes | Maximum number of nodes for the Connect nodepool when using autoscaling | number | 5 | Required, when `connect_nodepool_auto_scaling=true`, specified value must be between 1 and 100 |
| connect_nodepool_min_nodes | Minimum number of nodes for the Connect nodepool when using autoscaling | number | 1 | Required, when `connect_nodepool_auto_scaling=true`, specified value must be between 1 and 100 |
| connect_nodepool_taints | Taints for the Connect nodepool VMs | list of strings | ["workload.sas.com/class=connect:NoSchedule"] | |
| connect_nodepool_labels | Labels to add to the Connect nodepool VMs | map | {"workload.sas.com/class" = "connect"  "launcher.sas.com/prepullImage" = "sas-programming-environment" } | |
| connect_nodepool_availability_zones | Availability Zones for the Connect nodepool | list of strings | [] | Note: This value depends on the "location". For example, not all regions have numbered availability zones|

### Stateless Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_stateless_nodepool | Create Stateless nodepool | bool | true | |
| stateless_nodepool_vm_type | Type of the Stateless nodepool VMs | string | "Standard_D16s_v3" | |
| stateless_nodepool_os_disk_size | Disk size for Stateless nodepool VMs in GB | number | 200 | |
| stateless_nodepool_node_count| Number of Stateless nodepool VMs | number | 1 | The value must be between 1 and 100 and between `stateless_nodepool_min_nodes` and `stateless_nodepool_max_nodes`|
| stateless_nodepool_auto_scaling | Enable autoscaling for the Stateless nodepool | bool | true | | 
| stateless_nodepool_max_nodes | Maximum number of nodes for the Stateless nodepool when using autoscaling | number | 5 | Required, when `stateless_nodepool_auto_scaling=true`, specified value must be between 1 and 100|
| stateless_nodepool_min_nodes | Minimum number of nodes for the Stateless nodepool when using autoscaling | number | 1 | Required, when `stateless_nodepool_auto_scaling=true`, specified value must be between 1 and 100|
| stateless_nodepool_taints | Taints for the Stateless nodepool VMs | list of strings | ["workload.sas.com/class=stateless:NoSchedule"] | |
| stateless_nodepool_labels | Labels to add to the Stateless nodepool VMs | map | {"workload.sas.com/class" = "stateless" } | |
| stateless_nodepool_availability_zones | Availability Zones for the Stateless nodepool | list of strings | [] | Note: This value depends on the "location". For example, not all regions have numbered availability zones|
### Stateful Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_stateful_nodepool | Create Stateful nodepool | bool | true | |
| stateful_nodepool_vm_type | Type of the Stateful nodepool VMs | string | "Standard_D8s_v3" | |
| stateful_nodepool_os_disk_size | Disk size for Stateful nodepool VMs in GB | number | 200 | |
| stateful_nodepool_node_count| Number of Stateful nodepool VMs | number | 1 | The value must be between 1 and 100 and between `stateful_nodepool_min_nodes` and `stateful_nodepool_max_nodes`|
| stateful_nodepool_auto_scaling | Enable autoscaling for the Stateful nodepool | bool | true | |
| stateful_nodepool_max_nodes | Maximum number of nodes for the Stateful nodepool when using autoscaling | number | 3 | Required, when `stateful_nodepool_auto_scaling=true`, specified value must be between 1 and 100 |
| stateful_nodepool_min_nodes | Minimum number of nodes for the Stateful nodepool when using autoscaling | number | 1 | Required, when `stateful_nodepool_auto_scaling=true`, specified value must be between 1 and 100|
| stateful_nodepool_taints | Taints for the Stateful nodepool VMs | list of strings | ["workload.sas.com/class=stateful:NoSchedule"] | |
| stateful_nodepool_labels | Labels to add to the Stateful nodepool VMs | map | {"workload.sas.com/class" = "stateful" }  | |
| stateful_nodepool_availability_zones | Availability Zones for the Stateful nodepool | list of strings | [] | Note: This value depends on the "location". For example, not all regions have numbered availability zones|

## Storage
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| storage_type | Type of Storage. Valid Values: "dev", "standard", "ha"  | string | "dev" | "dev" creates AzureFile, "standard" creates NFS server VM, "ha" creates Azure Netapp Files|
### storage_type=dev - azurefile
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_jump_public_ip | Add public ip to jump VM | bool | true | The Jump/NFS VM are not created with storage_type="dev" |
| jump_vm_admin | OS Admin User for the Jump VM | string | "jumpuser" | The Jump/NFS VM are not created with storage_type="dev | 
### storage_type=standard - nfs server VM
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_nfs_public_ip | Add public ip to the NFS server VM | bool | false | The NFS server VM is only created when storage_type="standard" |
| nfs_vm_admin | OS Admin User for the NFS server VM | string | "nfsuser" | The NFS server VM is only created when storage_type="standard" |
| nfs_raid_disk_size | Size in Gb for each disk of the RAID5 cluster on the NFS server VM | number | 128 | The NFS server VM is only created when storage_type="standard" |
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
| postgres_administrator_login | The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created. | string | "pgadmin" | The admin login name cannot be azure_superuser, azure_pg_admin, admin, administrator, root, guest, or public. It cannot start with pg_. See https://docs.microsoft.com/en-us/azure/postgresql/quickstart-create-server-database-portal |
| postgres_administrator_password | The Password associated with the postgres_administrator_login for the PostgreSQL Server | string | | The password must contain between 8 and 128 characters and must contain characters from three of the following categories: English uppercase letters, English lowercase letters, numbers (0 through 9), and non-alphanumeric characters (!, $, #, %, etc.). |
| postgres_server_version | The version of the Azure Database for PostgreSQL server instance. Valid values are "9.5", "9.6", "10.0", and "11". Changing this forces a new resource to be created.| string | "11" | |
| postgres_ssl_enforcement_enabled | Enforce SSL on connection to the Azure Database for PostgreSQL server instance | bool | true | |
| postgres_db_names | List of names for databases to create for the Azure Database for PostgreSQL server instance. Each name needs to be a valid PostgreSQL identified. Changes this forces a new resource to be created. | list of strings | [] | |
| postgres_db_charset | The Charset for the PostgreSQL Database. Needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created. | string | "UTF8" | |
| postgres_db_collation | The Collation for the PostgreSQL Database. Needs to be a valid PostgreSQL Collation. Changing this forces a new resource to be created. |string| "English_United States.1252" | |
| postgres_firewall_rules | Firewall rules for the PostgreSQL Database server instance | list of maps | [] | Example:  [{ "name" = "LocalAccess", "start_ip" = "55.55.0.0", "end_ip" = "55.55.255.255" }] |
| postgres_configurations | Configurations to enable on the PostgreSQL Database server instance | map | {} | |




