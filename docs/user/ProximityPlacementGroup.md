
# Proximity Placement Groups (PPG)

## What they are

A proximity placement group is a logical grouping used to make sure that Azure compute resources are physically located close to each other. Proximity placement groups are useful for workloads where low latency is a requirement.

More information can be found [here.](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/co-location#proximity-placement-groups)

## Usage Information

A proximity placement group is a colocation constraint rather than a pinning mechanism. It is pinned to a specific data center with the deployment of the first resource to use it. Once all resources using the proximity placement group have been stopped (deallocated) or deleted, it is no longer pinned. Therefore, when using a proximity placement group with multiple VM series, it is important to specify all the required types upfront in a template when possible or follow a deployment sequence which will improve your chances for a successful deployment. If your deployment fails, restart the deployment with the VM size which has failed as the first size to be deployed.

More information can be found [here.](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/co-location#using-proximity-placement-groups)

## How they affect your deployment

Given that proximity placement groups need to create resources that exist in a single data center, the amount of resources one requests may not be available and may return errors when trying to create your cluster using the terraform code provided here. If that does happen, you will need to look at adjusting your cluster or find a region more suitable for the deployment you're looking to create.

More information can be found [here.](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/co-location#what-to-expect-when-using-proximity-placement-groups)

## Examples file

The [examples file](examples/sas-input-ppg.tfvars) has both the `min_nodes` and `max_nodes` set to the same value which will, as noted in the docs above, request that all resourcs for a given node pool be created at once in the same data center and also disable autoscalling for this node pool as all resources are created from the begining.
