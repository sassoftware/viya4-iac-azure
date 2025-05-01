# Community-Contributed Configuration Variables

Community-contributed configuration variables are listed in the tables below. These variables can also be specified on the terraform command line.

> [!CAUTION]
> Community members are responsible for maintaining these features. While project maintainers will verify these features work as expected when merged, they cannot guarantee future releases will not break them. If you encounter issues while using these features, start a [GitHub Discussion](https://github.com/sassoftware/viya4-iac-azure/discussions) or open a Pull Request to fix them. As a last resort, you can create a GitHub Issue.

## Table of Contents

* [Spot Nodes](#spot_nodes)

<a name="spot_nodes"></a>
## Spot Nodes

Here is some information about spot nodes.

Here is a warning about why they might cause issues.

Here is a table with the variables you would use to configure them

| Name | Description | Type | Default | Release Added | Notes |
| :--- | ---: | ---: | ---: | ---: | ---: |
| community_priority | (Optional) The Priority for Virtual Machines within the Virtual Machine Scale Set that powers this Node Pool. Possible values are Regular and Spot. Defaults to Regular. Changing this forces a new resource to be created. | string | `Regular` | 10.3.0 | Changing this to Spot enables the Spot node pool functionality |
| community_eviction_policy | (Optional) The Eviction Policy which should be used for Virtual Machines within the Virtual Machine Scale Set powering this Node Pool. Possible values are Deallocate and Delete. Changing this forces a new resource to be created. | string | `Delete` | 10.3.0 | |
| community_spot_max_price | (Optional) The maximum price you're willing to pay in USD per Virtual Machine. Valid values are -1 (the current on-demand price for a Virtual Machine) or a positive value with up to five decimal places. Changing this forces a new resource to be created. | string | `-1` | 10.3.0 | |

