# Azure Help Topics

## How to authenticate using AzureCLI

Ask your Azure Cloud administrator for your Subscription and Tenant IDs. You can find the information from Azure CLI upon login.

```yaml
az login
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "00000000-0000-0000-0000-000000000000",
    "id": "00000000-0000-0000-0000-000000000000",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Subscription Name",
    "state": "Enabled",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "user": {
      "name": "user@example.com",
      "type": "user"
    }
  }
]
```

You can also use the ```az account list``` command to list all the subscriptions and tenants you belong to. From Azure CLI commands, the value of `id` is used in `TF_VAR_subscription_id` and `tenantId` is used in `TF_VAR_tenant_id`.

## How to create Service Principal using AzureCLI

A Service Principal is effectively a "user" that you create to use with automated tools, like Terraform, to access Azure services on your behalf. You give it a role with only the permissions needed to execute the tasks that the ServicePrincipal performs on your behalf.

 
You can create a Service Principal to use with Terraform with the following steps. 

**Note:** You will need an Azure account with **'Owner'** role to perform these operations


```bash
az login # follow the instructions given by this command

TF_VAR_client_secret=$(az ad sp create-for-rbac --skip-assignment --name http://$USER --query password --output tsv)
TF_VAR_client_id=$(az ad sp show --id http://$USER --query appId --output tsv)

echo $TF_VAR_client_id
echo $TF_VAR_client_secret

az role assignment create --assignee $TF_VAR_client_id --role Contributor
```

You can use this command to list only your Service Principals in the Azure Subscription:

```bash
az ad sp list --show-mine -o table
```

If in case `$SP_PASSWD` value is lost or has expired, you can reset it with this command:

```bash
az ad sp credential reset --name http://$USER
```

If you don't have an Azure account with **Owner** role please check with your Azure account administrator. You can find more details on Azure documentation on how to `create/retrieve/manage/reset` [Azure Service Principal with AzureCLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest). 

To learn more about how Azure Role based access control works refer to the docs:

* [Role definitions](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-definitions-list)
* [List roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-cli#list-role-assignments-for-a-user)
* [Add or remove roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli#user-at-a-subscription-scope)


## How to grant a Service Principal access to Azure Container Registry

When creating a private Azure Container Registry assign 'acrpull' role to the Service Principal

```bash
  ACR_ID=$(terraform output cr_id)
  az role assignment create --assignee $TF_VAR_client_id --role acrpull  --scope "$ACR_ID"
```

## How to create a User-assigned Managed Identity with `Contributor` Role

* [Use the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-portal)

Following the Instructions in the link above, when you get the Role Assignment blade, use the following values:

* **Role**: "Contributor" 
* **Assign access to**: "User Assigned Managed Identity"
* **Select** - select the Managed Identity you just created from the list below that entry field

Press `Save` to create the Role Assignment.

* [Use the Azure CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli)

Example Code:
```
az identity create --resource-group <my resource group> --name <my identity name>
PID=$(az identity show --resource-group <my resource group> --name <my identity name> --output tsv --query principalId)
az role assignment create --assignee $PID --role Contributor
```
## How to assign User-assigned Managed Identity to a VM

* [Use the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm#user-assigned-managed-identity)

* [Use the Azure CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm#user-assigned-managed-identity)

