# Valid Configuration Variables

Supported configuration variables are listed in the tables below.  All variables can also be specified on the command line.  Values specified on the command line will override values in configuration defaults files.

## Table of Contents

- [Valid Configuration Variables](#valid-configuration-variables)
  - [Table of Contents](#table-of-contents)
  - [Required Variables](#required-variables)
    - [Azure Authentication](#azure-authentication)
  - [Role Based Access Control](#role-based-access-control)
  - [Admin Access](#admin-access)
  - [Security](#security)
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

## Role Based Access Control

The ability to manage RBAC for Kubernetes resources from Azure gives you the choice to manage RBAC for the cluster resources either using Azure or native Kubernetes mechanisms. For details see [Azure role-based access control](https://docs.microsoft.com/en-us/azure/aks/concepts-identity#azure-rbac-for-kubernetes-authorization).

Following are the possible ways to configure Authentication and Authorization in an AKS cluster:
1. Authentication using local accounts with Kubernetes RBAC. This is traditionally used and current default, see details [here](https://learn.microsoft.com/en-us/azure/aks/concepts-identity#kubernetes-rbac)
2. Microsoft Entra authentication with Kubernetes RBAC. See details [here](https://learn.microsoft.com/en-us/azure/aks/azure-ad-rbac)
3. Microsoft Entra authentication with Azure RBAC. See details [here](https://learn.microsoft.com/en-us/azure/aks/manage-azure-rbac)

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| rbac_aad_enabled | Enables Azure Active Directory integration with Kubernetes or Azure RBAC. | bool  | false |
| rbac_aad_azure_rbac_enabled | Enables Azure RBAC. If false and `rbac_aad_enabled` is true`, Kubernetes RBAC is used. Only relevant if rbac_aad_enabled is true. | bool  | false |
| rbac_aad_admin_group_object_ids | A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster. | list(string) | null | One of `rbac_aad_admin_group_object_ids` or `rbac_aad_tenant_id` is required if `rbac_aad_enabled` is true. Not relevant if `rbac_aad_azure_rbac_enabled` is true.
| rbac_aad_tenant_id | (Optional) The Tenant ID used for Azure Active Directory Application. If this isn't specified, the Tenant ID of the current Subscription is used.| string  | | One of `rbac_aad_admin_group_object_ids` or `rbac_aad_tenant_id` is required if `rbac_aad_enabled` is true.

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
| default_public_access_cidrs | IP address ranges allowed to access all created cloud resources | list of strings | | Sets a default for all resources. Not setting the CIDR range creates a fully public site, this is not recommended for security reasons. |
| cluster_endpoint_public_access_cidrs | IP address ranges allowed to access the AKS cluster API | list of strings | | For client admin access to the cluster api (by `kubectl`, for example). Only used with `cluster_api_mode=public`|
| vm_public_access_cidrs | IP address ranges allowed to access the VMs | list of strings | | Opens port 22 for SSH access to the jump server and/or NFS VM by adding Ingress Rule on the NSG. Only used with `create_jump_public_ip=true` or `create_nfs_public_ip=true`   |
| postgres_public_access_cidrs | IP address ranges allowed to access the Azure PostgreSQL Flexible Server | list of strings || Opens port 5432 by adding Ingress Rule on the NSG. Only used when creating postgres instances. |
| acr_public_access_cidrs | IP address ranges allowed to access the ACR instance | list of strings || Only used with `create_container_registry=true` |

**NOTE:** In a SCIM environment, the AzureActiveDirectory service tag must be granted access to port 443/HTTPS for the Ingress IP address.

## Security

The Federal Information Processing Standard (FIPS) 140 is a US government standard that defines minimum security requirements for cryptographic modules in information technology products and systems. Azure Kubernetes Service (AKS) allows the creation of node pools with FIPS 140-2 enabled. Deployments running on FIPS-enabled node pools provide increased security and help meet security controls as part of FedRAMP compliance. For more information on FIPS 140-2, see [Federal Information Processing Standard (FIPS) 140](https://learn.microsoft.com/en-us/azure/compliance/offerings/offering-fips-140-2).

To enable the FIPS support in your subscription, you first need to accept the legal terms of the `Ubuntu Pro FIPS 22.04 LTS` image that will be used in the deployment. For details see [Ubuntu Pro FIPS 22.04 LTS](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/canonical.0001-com-ubuntu-pro-jammy-fips?tab=Overview).

To accept the terms please run following az command before deploying cluster:

```bash
az vm image terms accept --urn Canonical:0001-com-ubuntu-pro-focal-fips:pro-fips-22_04-gen2:latest --subscription $subscription_id
```

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| fips_enabled | Enables the Federal Information Processing Standard for all the nodes and VMs in this cluster | bool | false | Make sure to accept terms mentioned above before deploying. |

## Networking

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | :--- |
| vnet_address_space | Address space for created vnet | string | "192.168.0.0/16" | This variable is ignored when vnet_name is set (AKA bring your own vnet). |
| subnets | Subnets to be created and their settings | map(object) | *check below* | This variable is ignored when subnet_names is set (AKA bring your own subnets). All defined subnets must exist within the vnet address space. |
| cluster_egress_type | The outbound (egress) routing method to be used for this Kubernetes Cluster | string | "loadBalancer" | Possible values: <ul><li>`loadBalancer`<li>`userDefinedRouting`</ul> By default, AKS will create and use a [loadbalancer](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard) for outgoing connections.<p>Set to `userDefinedRouting` when using your own network [egress](https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype).|
| aks_network_plugin | Network plugin to use for networking. | string | "kubenet"| Possible values are `kubenet` and `azure`. For details see Azure's documentation on: [Configure kubenet](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet), [Configure Azure CNI](https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni).<br>**Note**: To support Azure CNI your Subnet must be large enough to accommodate the nodes, pods, and all Kubernetes and Azure resources that might be provisioned in your cluster.<br>To calculate the minimum subnet size including an additional node for upgrade operations use formula: `(number of nodes + 1) + ((number of nodes + 1) * maximum pods per node that you configure)` <br>Example for a 5 node cluster: `(5) + (5 * 110) = 555 (/22 or larger)`|
| aks_network_policy | Sets up network policy to be used with Azure CNI. Network policy allows to control the traffic flow between pods. | string | null | Possible values are `calico` and `azure`. Network policy `azure` (Azure Network Policy Manager) is only supported for `aks_network_plugin = azure` and network policy `calico` is supported for both `aks_network_plugin` values `azure` and `kubenet`. For more details see [network policies in Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/use-network-policies).|
| aks_network_plugin_mode | Specifies the network plugin mode used for building the Kubernetes network. | string | null | Possible value is `overlay`. When `aks_network_plugin_mode` is set to `overlay` , the `aks_network_plugin` field can only be set to `azure`. For details see Azure's documentation on: [Configure Azure CNI Overlay networking](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay).|

The default values for the `subnets` variable are as follows:

```yaml
{
  aks = {
    "prefixes": ["192.168.0.0/23"],
    "service_endpoints": ["Microsoft.Sql"],
    "private_endpoint_network_policies": "Enabled",
    "private_link_service_network_policies_enabled": false,
    "service_delegations": {},
  }
  misc = {
    "prefixes": ["192.168.2.0/24"],
    "service_endpoints": ["Microsoft.Sql"],
    "private_endpoint_network_policies": "Enabled",
    "private_link_service_network_policies_enabled": false,
    "service_delegations": {},
  }
  ## If using ha storage then the following is also added
  netapp = {
    "prefixes": ["192.168.3.0/24"],
    "service_endpoints": [],
    "private_endpoint_network_policies": "Enabled",
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
| msi_network_roles | Roles that will be assigned to the vnet and route table | list of strings | ["Network Contributor"] | This field will only be used in the event that the User Assigned Identity is created by IaC. If this case the authenticating identity used to run Terraform must have [Permissions for Assigning Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal#prerequisites) scoped to the vnet and route table. |

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

Ubuntu 22.04 LTS is the operating system used on the Jump/NFS servers. Ubuntu creates the `/mnt` location as an ephemeral drive that cannot be used as the root location of the `jump_rwx_filestore_path` variable.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| partner_id | A GUID that is registered with Microsoft to facilitate partner resource usage attribution | string | "5d27f3ae-e49c-4dea-9aa3-b44e4750cd8c" | Defaults to SAS partner GUID. When you deploy this Terraform configuration, Microsoft can identify the installation of SAS software with the deployed Azure resources. Microsoft can then correlate the resources that are used to support the software. Microsoft collects this information to provide the best experiences with their products and to operate their business. The data is collected and governed by Microsoft's privacy policies, located at https://www.microsoft.com/trustcenter. |
| create_static_kubeconfig | Allows the user to create a provider / service account-based kubeconfig file | bool | true | A value of `false` will default to using the cloud provider's mechanism for generating the kubeconfig file. A value of `true` will create a static kubeconfig that uses a `Service Account` and `Cluster Role Binding` to provide credentials. |
| kubernetes_version | The AKS cluster Kubernetes version | string | "1.31" | Use of specific versions is still supported. If you need exact kubernetes version please use format `x.y.z`, where `x` is the major version, `y` is the minor version, and `z` is the patch version |
| create_jump_vm | Create bastion host | bool | true | |
| create_jump_public_ip | Add public IP address to the jump VM | bool | true | |
| enable_jump_public_static_ip | Enables `Static` allocation method for the public IP address of Jump Server. Setting false will enable `Dynamic` allocation method. | bool | true | Only used with `create_jump_public_ip=true` |
| jump_vm_admin | Operating system Admin User for the jump VM | string | "jumpuser" | |
| jump_vm_machine_type | SKU to use for the jump VM | string | "Standard_B2s" | To check for valid types for your subscription, run: `az vm list-skus --resource-type virtualMachines --subscription $subscription --location $location -o table` |
| jump_rwx_filestore_path | File store mount point on jump server | string | "/viya-share" | This location cannot include `/mnt` as its root location. This disk is ephemeral on Ubuntu, which is the operating system being used for the jump/NFS servers. |
| tags | Map of common tags to be placed on all Azure resources created by this script | map | { project_name = "sasviya4", environment = "dev" } | |
| aks_identity | Use UserAssignedIdentity or Service Principal as [AKS identity](https://docs.microsoft.com/en-us/azure/aks/concepts-identity) | string | "uai" | A value of `uai` wil create a Managed Identity based on the permissions of the authenticated user or use [`AKS_UAI_NAME`](#use-existing), if set. A value of `sp` will use values from [`CLIENT_ID`/`CLIENT_SECRET`](#azure-authentication), if set. |
| ssh_public_key | File name of public ssh key for jump and nfs VM | string | "~/.ssh/id_rsa.pub" | Required with `create_jump_vm=true` or `storage_type=standard` |
| cluster_api_mode | Public or private IP for the cluster api | string | "public" | Valid Values: "public", "private" |
| aks_cluster_private_dns_zone_id | Specifies private DNS zone resource ID for AKS private cluster to use | string | "" | For `cluster_api_mode=private` if `aks_cluster_private_dns_zone_id` is not specified then the value `System` is used else it is set to null. For details see [Configure a private DNS zone](https://learn.microsoft.com/en-us/azure/aks/private-clusters?tabs=azure-portal#configure-a-private-dns-zone) |
| aks_cluster_sku_tier | The SKU Tier that should be used for this Kubernetes Cluster. Optimizes api server for cost vs availability | string | "Free" | Valid Values:  "Free", "Standard" and "Premium" | 
| cluster_support_tier | Specifies the support plan which should be used for this Kubernetes Cluster. | string | "KubernetesOfficial" | Possible values are `KubernetesOfficial` and `AKSLongTermSupport`. To enable long term K8s support is a combination of setting `aks_cluster_sku_tier` to `Premium` tier and explicitly selecting the `cluster_support_tier` as `AKSLongTermSupport`. For details see [Long term Support](https://learn.microsoft.com/en-us/azure/aks/long-term-support) and for which K8s version has long term support see [AKS Kubernetes release calendar](https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli#aks-kubernetes-release-calendar). | 
| aks_cluster_run_command_enabled | Enable or disable the AKS Run Command feature | bool | false | The AKS Run Command feature in AKS allows you to remotely execute commands within a running container of your AKS cluster directly from the Azure CLI or Azure portal. To enable the Run Command feature for an AKS cluster where Run Command is disabled, navigate to the Run Command tab for your AKS Cluster in the Azure Portal and select the Enable button. |
| aks_azure_policy_enabled | Enable or disable the Azure Policy Add-on or extension | bool | false | Azure Policy makes it possible to manage and report on the compliance state of your Kubernetes cluster components from one place. By using Azure Policy's Add-on or Extension, governing your cluster components is enhanced with Azure Policy features, like the ability to use selectors and overrides for safe policy rollout and rollback. |
| node_resource_group_name | Specifies the resource group name for the cluster resources | string | `MC_${local.aks_rg.name}_${var.prefix}-aks_${var.location}` | |
| aks_cluster_sku_tier | The SKU Tier that should be used for this Kubernetes Cluster. Optimizes api server for cost vs availability | string | "Free" | Valid Values:  "Free", "Standard" and "Premium" |
| cluster_support_tier | Specifies the support plan which should be used for this Kubernetes Cluster. | string | "KubernetesOfficial" | Possible values are `KubernetesOfficial` and `AKSLongTermSupport`. To enable long term K8s support is a combination of setting `aks_cluster_sku_tier` to `Premium` tier and explicitly selecting the `cluster_support_tier` as `AKSLongTermSupport`. For details see [Long term Support](https://learn.microsoft.com/en-us/azure/aks/long-term-support) and for which K8s version has long term support see [AKS Kubernetes release calendar](https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli#aks-kubernetes-release-calendar).|
| aks_cluster_run_command_enabled | Enable or disable the AKS Run Command feature | bool | false | The AKS Run Command feature in AKS allows you to remotely execute commands within a running container of your AKS cluster directly from the Azure CLI or Azure portal. To enable the Run Command feature for an AKS cluster where Run Command is disabled, navigate to the Run Command tab for your AKS Cluster in the Azure Portal and select the Enable button. |
| aks_azure_policy_enabled | Enable or disable the Azure Policy Add-on or extension | bool | false | Azure Policy makes it possible to manage and report on the compliance state of your Kubernetes cluster components from one place. By using Azure Policy's Add-on or Extension, governing your cluster components is enhanced with Azure Policy features, like the ability to use selectors and overrides for safe policy rollout and rollback. |

## Node Pools

### Default Node Pool

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| node_vm_admin | Operating system Admin User for VMs of AKS cluster nodes | string | "azureuser" | |
| default_nodepool_vm_type | Type of the default node pool VMs | string | "Standard_E8s_v5" | |
| default_nodepool_os_disk_size | Disk size for default node pool VMs in GB | number | 128 ||
| default_nodepool_max_pods | Maximum number of pods that can run on each | number | 110 | Changing this forces a new resource to be created. |
| default_nodepool_min_nodes | Minimum and initial number of nodes for the default node pool | number | 1 |  Value must be between 0 and 100. Setting min and max node counts the same disables autoscaling. |
| default_nodepool_max_nodes | Maximum number of nodes for the default node pool| number | 5 | Value must be between 0 and 100. Setting min and max node counts to the same value  disables autoscaling. |
| default_nodepool_availability_zones | Availability Zones for the cluster default node pool | list of strings | ["1"]  | **NOTE:** This value depends on the "location". For example, not all regions have numbered availability zones.|

### Additional Node Pools

Additional node pools can be created separate from the default node pool. This is done with the `node_pools` variable, which is a map of objects. Irrespective of the default values, the following variables are required for each node pool unless marked optional:

| Name | Description | Type | Notes |
| :--- | ---: | ---: | ---: |
| machine_type | Type of the node pool VMs | string | |
| os_disk_size | Disk size for node pool VMs in GB | number | |
| min_nodes | Minimum number of nodes for the node pool | number | Value must be between 0 and 100. Setting min and max node counts to the same value disables autoscaling |
| max_nodes | Maximum number of nodes for the node pool | number | Value must be between 0 and 100. Setting min and max node counts to the same value disables autoscaling |
| max_pods | Maximum number of pods per node | number | Default is 110 |
| node_taints | Taints for the node pool VMs | list of strings | |
| node_labels | Labels to add to the node pool VMs | map | |
| vm_max_map_count (Optional) | Linux kernel parameter that defines the maximum number of memory map areas that a process can have | map | Value is set as follows: "linux_os_config" = {"sysctl_config" = {"vm_max_map_count" = 262144}} |

The default values for the `node_pools` variable are as follows:

**Note**: SAS recommends that you maintain a minimum of 1 node in the pool for `compute` workloads. This allocation ensures that compute-related pods have the required images pulled and ready for use in the environment..

```yaml
{
  cas = {
    "machine_type"          = "Standard_E16ds_v5"
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
    "machine_type"          = "Standard_D4ds_v5"
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
    "machine_type"          = "Standard_D4s_v5"
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
    "machine_type"          = "Standard_D4s_v5"
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
| node_pools_availability_zone | Availability Zone for the additional node pools and the NFS VM, for `storage_type="standard"`| string | "1" | The possible values depend on the region set in the "location" variable. |
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
| enable_nfs_public_static_ip | Enables `Static` allocation method for the public IP address of NFS Server. Setting false will enable `Dynamic` allocation method | bool | true | Only used with `create_nfs_public_ip=true` |
| nfs_vm_admin | OS Admin User for the NFS server VM | string | "nfsuser" | |
| nfs_vm_machine_type | SKU to use for NFS server VM | string | "Standard_D4s_v5" | To check for valid types for your subscription, run: `az vm list-skus --resource-type virtualMachines --subscription $subscription --location $location -o table`|
| nfs_vm_zone | Zone in which NFS server VM should be created | string | null | |
| nfs_raid_disk_type | Managed disk types | string | "Standard_LRS" | Supported values: Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS. When using `UltraSSD_LRS`, `nfs_vm_zone` and `nfs_raid_disk_zone` must be specified. See the [Azure documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/disks-enable-ultra-ssd) for limitations on Availability Zones and VM types. |
| nfs_raid_disk_size | Size in Gb for each disk of the RAID5 cluster on the NFS server VM | number | 256 | |
| nfs_raid_disk_zone | The Availability Zone in which the Managed Disk should be located. Changing this property forces a new resource to be created. | string | null | |

### Azure NetApp Files (only when `storage_type=ha`)

When `storage_type=ha` (high availability), [Microsoft Azure NetApp Files](https://azure.microsoft.com/en-us/services/netapp/) service is created, only when these variables are applicable. Before using this storage option, read about how to [Register for Azure NetApp Files](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-register) to ensure your Azure Subscription has been granted access to the service.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| netapp_service_level | The target performance level of the file system. Valid values include Premium, Standard, or Ultra. | string | "Premium" | |
| netapp_size_in_tb | Provisioned size of the pool in TB. Value must be between 4 and 500 | number | 4 | |
| netapp_protocols | The target volume protocol expressed as a list. Supported single value include CIFS, NFSv3, or NFSv4.1. If argument is not defined, it defaults to NFSv4.1. Changing this forces a new resource to be created and data will be lost. | list of strings | ["NFSv4.1"] | |
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
| sku_name| The SKU Name for the PostgreSQL Flexible Server | string | "GP_Standard_D4ds_v5" | The name pattern is the SKU, followed by the tier + family + cores (e.g. B_Standard_B1ms, GP_Standard_D2s_v5, MO_Standard_E4s_v5).|
| storage_mb | The max storage allowed for the PostgreSQL Flexible Server | number | 131072 | Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, and 33554432. |
| backup_retention_days | Backup retention days for the PostgreSQL Flexible server | number | 7 | Supported values are between 7 and 35 days. |
| geo_redundant_backup_enabled | Enable Geo-redundant or not for server backup | bool | false | Not supported for the basic tier. |
| administrator_login | The Administrator Login for the PostgreSQL Flexible Server. Changing this forces a new resource to be created. | string | "pgadmin" | The admin login name cannot be azure_superuser, azure_pg_admin, admin, administrator, root, guest, or public. It cannot start with pg_. See: [Microsoft Quickstart Server Database](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/quickstart-create-server-portal) |
| administrator_password | The Password associated with the administrator_login for the PostgreSQL Flexible Server | string | "my$up3rS3cretPassw0rd" | The password must contain between 8 and 128 characters and must contain characters from three of the following categories: English uppercase letters, English lowercase letters, numbers (0 through 9), and non-alphanumeric characters (!, $, #, %, etc.). |
| server_version | The version of the PostgreSQL Flexible server instance | string | "15" | Refer to the [SAS Viya Platform Administration Guide](https://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=itopssr&docsetTarget=p05lfgkwib3zxbn1t6nyihexp12n.htm#p1wq8ouke3c6ixn1la636df9oa1u) for the supported versions of PostgreSQL for the SAS Viya platform. |
| ssl_enforcement_enabled | Enforce SSL on connection to the Azure Database for PostgreSQL Flexible server instance | bool | true | |
| connectivity_method | Network connectivity option to connect to your flexible server. There are two connectivity options available: Public access (allowed IP addresses) and Private access (VNet Integration). Defaults to public access with firewall rules enabled.| string | "public" | Valid options are `public` and `private`. See sample input file [here](../examples/sample-input-postgres.tfvars) and Private access documentation [here](./user/PostgreSQLPrivateAccess.md). For more details see [Networking overview](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking) |
| postgresql_configurations | Sets a PostgreSQL Configuration value on a Azure PostgreSQL Flexible Server | list(object) | [{ name : "azure.extensions", value : "PGCRYPTO" }] | More details can be found [here](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/howto-configure-server-parameters-using-cli) |

Multiple SAS offerings require a second PostgreSQL instance referred to as SAS Common Data Store, or CDS PostgreSQL. For more information, see [Common Customizations](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#p0wkxxi9s38zbzn19ukjjaxsc0kl). A list of SAS offerings that require CDS PostgreSQL is provided in [SAS Common Data Store Requirements](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=itopssr&docsetTarget=p05lfgkwib3zxbn1t6nyihexp12n.htm#n03wzanutmc6gon1val5fykas9aa). To create and configure an external CDS PostgreSQL instance in addition to the external platform PostgreSQL instance named `default`, specify `cds-postgres` as a second PostgreSQL instance, as shown in the example below.

Here is an example of the `postgres_servers` variable with the `default` server entry overriding only the `administrator_password` and `postgresql_configurations` parameters, and the `cds-postgres` entry overriding the `sku_name`, `storage_mb`, `backup_retention_days`, `administrator_login` and `administrator_password` parameters:

```terraform
postgres_servers = {
  default = {
    administrator_password       = "D0ntL00kTh1sWay"
    postgresql_configurations    = [
       {
         name  = "azure.extensions"
         value = "PGCRYPTO,LTREE"
       }
      ]
  },
  cds-postgres = {
    sku_name                     = "GP_Standard_D4ds_v5"
    storage_mb                   = 131072
    backup_retention_days        = 7
    administrator_login          = "pgadmin"
    administrator_password       = "1tsAB3aut1fulDay"
  }
}
```
