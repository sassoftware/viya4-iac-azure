### Authenticating Terraform to access Azure

Terraform supports multiple ways of authenticating to Azure. This project chooses to use Azure Service Principal and Secret for authentication, see [Terraform documentation](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html). In order to create and destroy Azure objects on your behalf, Terraform also needs information about Azure Tenant and Subscription ids, as well as a Service Principal and Secret. 

See [Azure Help Topics](./docs/user/AzureHelpTopics.md) on how to get the values for these environment variables - `SUBSCRIPTION_ID, TENANT_ID, SP_APPID, SP_PASSWD`

**Note** Keep track of `SP_APPID` and `SP_PASSWORD` since Azure Service Principal only need to be created once. 

Run these export commands with respective values, to setup the required environments for Terraform to authenticate to Azure. These commands have to be run every time a new Terminal session is started.

```
# export needed IDs and Secrets
export ARM_SUBSCRIPTION_ID="SUBSCRIPTION_ID"
export ARM_TENANT_ID="TENANT_ID"
export ARM_CLIENT_ID="SP_APPID"
export ARM_CLIENT_SECRET="SP_PASSWD"
export TF_VAR_client_id="SP_APPID"
export TF_VAR_client_secret="SP_PASSWD"
```
**Tip:** Copy these commands to a secure local file - `$HOME/.azure_creds.sh` \
Now every time you need to setup these environment values in a new Terminal session, just run this command -
```
source $HOME/.azure_creds.sh
```