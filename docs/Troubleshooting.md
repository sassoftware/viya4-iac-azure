# Troubleshooting

## Failure to delete AKS Node Pool

There is a bug that has no real owner at this time that sometimes requires one to run the `terraform destroy` command twice before all resources are removed from terraform.

Here is a sample of the error:

```bash
Error: waiting for the deletion of Node Pool "stateful" (Managed Kubernetes Cluster "viya-tst1-aks" / Resource Group "viya-tst1-rg"): Code="Canceled" Message="The operation was overriden and canceled by a later operation e99c6c8f-18cb-46de-8142-4c87b7a2add0."
```

## Import Azure Resource into Terraform state

```bash
Error: A resource with the ID "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/viya-tst-rg/providers/Microsoft.ContainerService/managedClusters/viya-tst-aks/agentPools/stateless" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_kubernetes_cluster_node_pool" for more information.
```

**Resolution:**

```bash
terraform import -var-file=sample-input.tfvars module.aks.azurerm_kubernetes_cluster.aks '/subscription/00000000-0000-0000-0000-000000000000/../../'
```

## Not able to access AKS with kubectl

```bash
Error: authorization.RoleAssignmentsClient#Create: Failure responding to request: StatusCode=403 -- Original Error: autorest/azure: Service returned an error. Status=403 Code="AuthorizationFailed" Message="The client '63fac752-e2c4-4cff-ba97-000000000000' with object id '63fac752-e2c4-4cff-ba97-000000000000' does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write' over scope '/subscriptions/85704435-0cf9-4366-bf03-ef93f952145a/resourceGroups/viya-tst-rg/providers/Microsoft.ContainerRegistry/registries/viyatstacr/providers/Microsoft.Authorization/roleAssignments/9dbdfe61-77d6-d985-a308-000000000000' or the scope is invalid. If access was recently granted, please refresh your credentials."

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
