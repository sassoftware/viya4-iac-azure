### Authenticating Terraform to access Azure

Terraform supports multiple ways of authenticating to Azure. This project chooses to use Azure Service Principal and Secret for authentication, see [Terraform documentation](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html). In order to create and destroy Azure objects on your behalf, Terraform also needs information about Azure Tenant and Subscription ids, as well as a Service Principal and Secret. 

See [Azure Help Topics](./AzureHelpTopics.md) on how to get the values for these environment variables - `SUBSCRIPTION_ID, TENANT_ID, SP_APPID, SP_PASSWD`

**Note:** Keep track of `SP_APPID` and `SP_PASSWORD` since Azure Service Principal only need to be created once. 


You can [set these variables in your `*.tfvars` file](../CONFIG-VARS.md##azure-authentication). But since they contain sensitive information, we recommend to use Terraform environment variables instead.

Run these commands to initialize the environment for the project. These commands will need to be run and pulled  into your environment each time you start a new session to use this repo and terraform.

```
# export needed ids and secrets
export TF_VAR_subscription_id=[SUBSCRIPTION_ID]
export TF_VAR_tenant_id=[TENANT_ID]
export TF_VAR_client_id=[SP_APPID]
export TF_VAR_client_secret=[SP_PASSWD]
```

**TIP:** These commands can be stored in a file outside of this repo in a secure file. \
Use your favorite editor, take the content above and save it to a file called: `$HOME/.azure_creds.sh` . (Protect that file so only you have read access to it.) \
Now each time you need these values you can do the following:

```
source $HOME/.azure_creds.sh
```

This will pull in those values into your current terminal session. Any terraform commands submitted in that session will use those values.

