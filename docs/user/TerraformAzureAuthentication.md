# Authenticating Terraform to Access Microsoft Azure

In order to create and destroy Microsoft Azure resources on your behalf, Terraform needs an identity with sufficient permissions to perform all the actions defined in the Terraform manifest. You can use a **Service Principal** or, when running on an Azure VM, a **User-assigned Managed Identity** to grant Terraform access to your Azure subscription. See [Azure Help Topics](./AzureHelpTopics.md) for more information about how to retrieve these values from Azure.

Your Service Principal or Managed Identity in the Azure subscription requires a **"Contributor"** role to create Azure resources. Follow these links for more information about how to create and retrieve the values to configure Terraform access to Azure: 

- [How to Create a Service Principal](./AzureHelpTopics.md#how-to-create-service-principal-using-azurecli) | See Using a Service Principal Below

- [How to Create a Managed Identity](./AzureHelpTopics.md#how-to-create-a-user-assigned-managed-identity-with-contributor-role) and [How to Assign the Managed Identity to a VM](./AzureHelpTopics.md#how-to-assign-a-user-assigned-managed-identity-to-a-vm)

We recommend using [TF_VAR_name](https://www.terraform.io/docs/cli/config/environment-variables.html#tf_var_name) environment variables to pass the authentication information to Terraform. 

## Using a Service Principal

To authenticate Terraform to access Azure, set the following four input variables:

| Name | Description | Type | Default |
| :--- | ---: | ---: | ---: |
| tenant_id | your Azure tenant id | string  | |
| subscription_id | your Azure subscription id | string  | |
| client_id | your app_id when using a Service Principal | string | "" |
| client_secret | your client secret when using a Service Principal| string | ""|

The following TF variables are required:

```
TF_VAR_tenant_id=00000000-0000-0000-0000-000000000000
TF_VAR_subscription_id=00000000-0000-0000-0000-000000000000
TF_VAR_client_id=00000000-0000-0000-0000-000000000000
TF_VAR_client_secret=00000000-0000-0000-0000-000000000000
```

There are several options for setting the TF variables. See [Terraform Usage](TerraformUsage.md).

## Using a User-assigned Managed Identity

To authenticate Terraform to access Azure when running on an Azure VM, set the following three input variables:

| Name | Description | Type | Default |
| :--- | ---: | ---: | ---: |
| tenant_id | your Azure tenant id | string  | |
| subscription_id | your Azure subscription id | string  | |
| use_msi | use the Managed Identity of your Azure VM | bool | true |

In this environment, the TF_VAR_name environment variables for these would be as follows:

```
TF_VAR_tenant_id=00000000-0000-0000-0000-000000000000
TF_VAR_subscription_id=00000000-0000-0000-0000-000000000000
TF_VAR_use_msi=true
```

