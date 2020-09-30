# Azure Help Topics

## Authentication using AzureCLI

Ask your Azure Cloud administrator for your Tenant and Subscription IDs. Or you can find the information from Azure CLI upon login.

```
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
You can also use the 
```az account list``` command to list all the subscriptions and tenants you belong to. From the output value of `id` is used in `SUBSCRIPTION_ID` and value of `tenantId` is used in `TENANT_ID`

## Service Principal using AzureCLI
A Service Principal is effectively a "user" that you create to use with automated tools, like Terraform, to access Azure services on your behalf. You give it a role with only the permissions needed to execute the tasks that the ServicePrincipal performs on your behalf.

If you do not have a Service Principal to use with Terraform, you can create one with the following steps. However, you will need an Azure Principal with 'Owner' role to perform these operations, if not check with your Azure account administrator. Refer to these Azure docs to learn more about
* [Role definitions](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-definitions-list)
* [List roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-cli#list-role-assignments-for-a-user)
* [Add or remove roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli#user-at-a-subscription-scope)

```
az login # follow the instructions given by this command

SP_PASSWD=$(az ad sp create-for-rbac --skip-assignment --name http://$USER --query password --output tsv)
SP_APPID=$(az ad sp show --id http://$USER --query appId --output tsv)

echo $SP_APPID
echo $SP_PASSWD

az role assignment create --assignee $SP_APPID --role Contributor
```

You can use this command to list only your Service Principals in the Azure Subscription.
```
az ad sp list --show-mine -o table
```

If in case `$SP_PASSWD` value is lost or has expired, you can reset it with this command
```
az ad sp credential reset --name http://$USER
```

You can find more details on Azure documentation on how to `create/retrieve/manage/reset` [Azure Service Principal with AzureCLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest)


## Service Principal access to Azure Container Registry
When creating a private Azure Container Registry assign 'acrpull' role to the Service Principal

    ACR_ID=$(terraform output acr_id)
    az role assignment create --assignee $SP_APPID --role acrpull  --scope "$ACR_ID"
