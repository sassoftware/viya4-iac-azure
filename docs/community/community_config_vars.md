# Community-Contributed Configuration Variables

Community-contributed configuration variables are listed in the tables below. These variables can also be specified on the terraform command line.

> [!CAUTION]
> Community members are responsible for maintaining these features. While project maintainers will verify these features work as expected when merged, they cannot guarantee future releases will not break them. If you encounter issues while using these features, start a [GitHub Discussion](https://github.com/sassoftware/viya4-iac-azure/discussions) or open a Pull Request to fix them. As a last resort, you can create a GitHub Issue.

## Table of Contents

* [Spot Nodes](#spot_nodes)
* [Netapp Volume Size](#netapp_volume_size)

<a name="spot_nodes"></a>
## Spot Nodes

Spot Nodes allow you to run Azure Kubernetes Service (AKS) workloads on low-cost, surplus compute capacity offered by Azure. These Spot Virtual Machines (VMs) can significantly reduce infrastructure costs, especially for workloads that are fault-tolerant or batch-oriented or temporary lab environments. However, Spot VMs can be preempted (evicted) by Azure at any time if the capacity is needed elsewhere, which makes them less suitable for critical or stateful workloads.

For further information, see https://learn.microsoft.com/en-us/azure/aks/spot-node-pool

> [!CAUTION] 
> Spot nodes can be evicted with little notice. They are best used for non-production, non-critical workloads or for scenarios where cost savings outweigh the risk of eviction. This is a configuration not supported by SAS Technical Support. Monitor eviction rates and ensure your workloads can tolerate sudden node loss.

To enable a Spot node pool in your AKS cluster using this module, configure the community-maintained variables listed below. These options customize the behavior of the Spot node pool and its underlying virtual machine scale set.

| Name | Description | Type | Default | Release Added | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| community_priority | (Optional) The Priority for Virtual Machines within the Virtual Machine Scale Set that powers this Node Pool. Possible values are Regular and Spot. Defaults to Regular. Changing this forces a new resource to be created. | string | `Regular` | 10.3.0 | Changing this to Spot enables the Spot node pool functionality |
| community_eviction_policy | (Optional) The Eviction Policy which should be used for Virtual Machines within the Virtual Machine Scale Set powering this Node Pool. Possible values are Deallocate and Delete. Changing this forces a new resource to be created. | string | `Delete` | 10.3.0 | |
| community_spot_max_price | (Optional) The maximum price you're willing to pay in USD per Virtual Machine. Valid values are -1 (the current on-demand price for a Virtual Machine) or a positive value with up to five decimal places. Changing this forces a new resource to be created. | string | `-1` | 10.3.0 | |

<a name="netapp_volume_size"></a>
## Netapp Volume Size

Netapp Volume Size control allows you to create a Netapp Volume smaller than the Netapp Pool. This will allow other tools outside of this Terraform to create Netapp Volumes within the pool.

To control the Netapp Volume size use the below community-maintained variable listed below. This will allow you to control the size of the Netapp Volume in GBs. This value must be smaller than the Netapp Pool size. There is no validation for this during the planning phase of Terraform. If this is misconfigured, the Terraform Apply will fail when attempting to deploy the volume.

| Name | Description | Type | Default | Release Added | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| community_netapp_volume_size | Size of the netapp volume | number | 0 | 10.3.0 | Zero will disable, must be smaller than the Netapp Pool. The value is given in GB |
