# Troubleshooting

##  Kubernetes Version is not supported in Azure region
```bash
Error: creating Managed Kubernetes Cluster "viya-tst-aks" (Resource Group "viya-tst-rg"): containerservice.ManagedClustersClient#CreateOrUpdate: Failure sending request: StatusCode=0 -- Original Error: Code="AgentPoolK8sVersionNotSupported" Message="Version 1.18.14 is not supported in this region. Please use [az aks get-versions] command to get the supported version list in this region. For more information, please check https://aka.ms/supported-version-list"

  on modules/azure_aks/main.tf line 2, in resource "azurerm_kubernetes_cluster" "aks":
   2: resource "azurerm_kubernetes_cluster" "aks" {
```
**Resolution:**
Run this Azure CLI command to get the supported Kubernetes versions in your Azure region and use value for `kubernetes_version` variable in input tfvars.
```bash
az aks get-versions --location <YOUR_AZURE_LOCATION> --output table 
```

## Failure to delete AKS Node Pool

There is a bug that has no real owner at this time that sometimes requires one to run the `terraform destroy` command twice before all resources are removed from terraform.

Here is a sample of the error:

```bash
Error: waiting for the deletion of Node Pool "stateful" (Managed Kubernetes Cluster "viya-tst1-aks" / Resource Group "viya-tst1-rg"): Code="Canceled" Message="The operation was overriden and canceled by a later operation REDACTED."
```

## Import Azure Resource into Terraform state

```bash
Error: A resource with the ID "/subscriptions/REDACTED/resourcegroups/viya-tst-rg/providers/Microsoft.ContainerService/managedClusters/viya-tst-aks/agentPools/stateless" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_kubernetes_cluster_node_pool" for more information.
```

**Resolution:**

```bash
terraform import -var-file=sample-input.tfvars module.aks.azurerm_kubernetes_cluster.aks '/subscription/REDACTED/../../'

terraform import -var-file=./terraform.tfvars module.node_pools[\"stateless\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0] "/subscriptions/.../resourcegroups/.../providers/Microsoft.ContainerService/managedClusters/.../agentPools/stateless"
```

## Not able to access AKS with kubectl

```bash
Error: authorization.RoleAssignmentsClient#Create: Failure responding to request: StatusCode=403 -- Original Error: autorest/azure: Service returned an error. Status=403 Code="AuthorizationFailed" Message="The client 'REDACTED' with object id 'REDACTED' does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write' over scope '/subscriptions/REDACTED/resourceGroups/viya-tst-rg/providers/Microsoft.ContainerRegistry/registries/viyatstacr/providers/Microsoft.Authorization/roleAssignments/REDACTED' or the scope is invalid. If access was recently granted, please refresh your credentials."

  on modules/azurerm_container_registry/main.tf line 18, in resource "azurerm_role_assignment" "acr":
  18: resource "azurerm_role_assignment" "acr" {
```

**Resolution:**
Check values of environment variables - `ARM_* and TF_*`

## Azure NetApp Files creation fails

```bash
Error: Error creating NetApp Account "sse-vdsdp-ha1-netappaccount" (Resource Group "sse-vdsdp-ha1-rg"): netappre sending request: StatusCode=404 -- Original Error: Code="InvalidResourceType" Message="The resource type cocrosoft.NetApp' for api version '2019-10-01'."


  on modules/azurerm_netapp/main.tf line 29, in resource "azurerm_netapp_account" "anf":
  29: resource "azurerm_netapp_account" "anf" {
 ```

 **Resolution:**
 Check your Azure Subscription has been granted access to Azure NetApp Files service: [Azure Netapp Quickstart](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-quickstart-set-up-account-create-volumes?tabs=azure-portal#before-you-begin)
