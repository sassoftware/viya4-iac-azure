# Azure Help Topics

## How to Authenticate Using the Azure CLI

You can **either** ask your Azure Cloud administrator for your subscription and tenant IDs, **or** you can find the information from the Azure CLI at login (see below):

```yaml
# example of an Azure CLI login command
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

## How to Set the TF Environment Variables

You can use the following commands, or alter them as needed to set the environment variables with your `Tenant ID` and `Subscription`:

```bash
# the following commands should work and should establish `TF_VAR_subscription_id` and `TF_VAR_tenant_id`
# az account list and az account show are helpful commands to determine this information
# for example, az account show --query '[environmentName, name, tenantId, user.name]'

# set the tenant ID from a query; validate
TF_VAR_tenant_id=$(az account show --query 'tenantId' --output tsv)
echo $TF_VAR_tenant_id

# set the subscription ID from a query; validate
TF_VAR_subscription_id=$(az account show --query 'id' --output tsv)
echo $TF_VAR_subscription_id
```

## How to Create a Service Principal Using the Azure CLI

A Service Principal is effectively a "user" that you create in order to enable automated tools, like Terraform, to access Azure services on your behalf. You give it a role with only the permissions needed to execute the tasks that the Service Principal performs on your behalf.
 
You can create a Service Principal to use with Terraform by taking the following steps:

**_NOTE:_** You will need an Azure account with an **'Owner'** role to perform these operations. The Service Principal name must be unique. You might need to change the value using `--name http://$USER` if it exists already.

```bash
az login # follow the instructions given by this command

TF_VAR_client_secret=$(az ad sp create-for-rbac --role "Contributor" --scopes="/subscriptions/$TF_VAR_subscription_id" --name http://$USER --query password --output tsv)
TF_VAR_client_id=$(az ad sp list --display-name http://$USER --query [].appId --output tsv)

echo $TF_VAR_client_id
echo $TF_VAR_client_secret
```

You can use this command to list only your Service Principals in the Azure subscription:

```bash
az ad sp list --show-mine -o table
```

In a case where the value for `$TF_VAR_client_secret` is lost or has expired, you can reset it with this command:

```bash
az ad sp credential reset --name http://$USER
```

If you don't have an Azure account with **Owner** role, check with your Azure account administrator. You can find more information about how to `create/retrieve/manage/reset` in the Azure documentation. See [Azure Service Principal with AzureCLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest). 

To learn more about how Azure Role-Based Access Control works, refer to the following documents:

* [Role definitions](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-definitions-list)
* [List roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-cli#list-role-assignments-for-a-user)
* [Add or remove roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli#user-at-a-subscription-scope)


## How to Grant a Service Principal Access to the Azure Container Registry

When creating a private Azure Container Registry, assign 'acrpull' role to the Service Principal:

```bash
  ACR_ID=$(terraform output cr_id)
  az role assignment create --assignee $TF_VAR_client_id --role acrpull  --scope "$ACR_ID"
```

## How to Create a User-assigned Managed Identity with the `Contributor` Role

Follow the instructions in [Use the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-portal). When you get the Role Assignment blade, use the following values:

- **Role**: "Contributor" 
- **Assign access to**: "User Assigned Managed Identity"
- **Select** - Select the Managed Identity you just created from the list below that entry field

Click **Save** to create the role assignment.

* [Use the Azure CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli)

Example Code:

```
az identity create --resource-group <my resource group> --name <my identity name>
PID=$(az identity show --resource-group <my resource group> --name <my identity name> --output tsv --query principalId)
az role assignment create --assignee $PID --role Contributor
```
## How to Assign a User-assigned Managed Identity to a VM

You can use the Azure Portal user interface or the Azure CLI to assign a managed identity to a VM in Microsoft Azure. Consult one of the following documents for instructions:

- [Use the Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm#user-assigned-managed-identity)
- [Use the Azure CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm#user-assigned-managed-identity)
