# Authenticating Terraform to access Azure

In order to create and destroy Azure resources on your behalf, Terraform needs an identity with sufficient permissions to perform all the actions defined in the Terraform manifest. You can use a **Service Principal** or, when running on an Azure VM, **User-assigned Managed Identity** to grant Terraform access to your Azure Subscription. See [Azure Help Topics](./AzureHelpTopics.md) for more information on how to retrieve their values from Azure.

Your Service Principal or Managed Identity in the Azure subscription requires a **"Contributor"** role to create Azure resources. Follow these links for more information on how to create and retrieve the values to configure Terraform access to Azure. 

- [How to create a Service Principal](./AzureHelpTopics.md#service-principal-using-azurecli) | See Using a Service Principal Below

- [How to create a Managed Identity](./AzureHelpTopics.md#how-to-create-a-user-assigned-managed-identity-with-contributor-role) and [how to assign the Managed Identity to a VM](./AzureHelpTopics.md#how-to-assign-a-user-assigned-managed-identity-to-a-vm)

We recommend using [TF_VAR_name](https://www.terraform.io/docs/cli/config/environment-variables.html#tf_var_name) environment variables to pass the authentication information to Terraform. 

## Using a Service Principal

To authenticate Terraform to access Azure, you will need to set the following four input variables:

| Name | Description | Type | Default |
| :--- | ---: | ---: | ---: |
| tenant_id | your Azure tenant id | string  | |
| subscription_id | your Azure subscription id | string  | |
| client_id | your app_id when using a Service Principal | string | "" |
| client_secret | your client secret when using a Service Principal| string | ""|

The following [bash (code) script](../../files/TerraformEnvVariableAssignment.sh) can be used to (re)assign the TF Environment Variables:

## Using an User-assigned Managed Identity

To authenticate Terraform to access Azure when running on an Azure VM, you will need to set the following three input variables:

| Name | Description | Type | Default |
| :--- | ---: | ---: | ---: |
| tenant_id | your Azure tenant id | string  | |
| subscription_id | your Azure subscription id | string  | |
| use_msi | use the Managed Identity of your Azure VM | bool | true |

TF_VAR_name environment variables for these would be

```
TF_VAR_tenant_id=00000000-0000-0000-0000-000000000000
TF_VAR_subscription_id=00000000-0000-0000-0000-000000000000
TF_VAR_use_msi=true
```

