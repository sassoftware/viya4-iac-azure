# Authenticating Terraform to access Azure

In order to create and destroy Azure objects on your behalf, Terraform needs to log in to Azure with an identity that has sufficient permissions to perform all the actions defined in the terraform manifest.

You can use a Service Principal or, when running on an Azure VM, a Managed Identity.

Your Service Principal or Managed Identity will need a Role Assignment with the "Contributor" Role for your Azure Subscription.

## Creating Authentication Resources
- [How to create a Service Principal](./AzureHelpTopics.md#service-principal-using-azurecli)

- [How to create a Managed Identity](./AzureHelpTopics.md#create-a-managed-identity-with-contributor-role-assignment) and [how to assign the Managed Identity to a VM](./AzureHelpTopics.md#assign-the-managed-identity-to-a-vm)


## Using A Service Principal to authenticate with Terraform

When using a Service Principal to authenticate with Terraform, you will need to set the following four terraform variables:

| Name | Description | Type | Default |
| :--- | ---: | ---: | ---: |
| tenant_id | your Azure tenant id | string  |
| subscription_id | your Azure subscription id | string  |
| client_id | your app_id when using a Service Principal | string | "" |
| client_secret | your client secret when using a Service Principal| string | "" |

See [Azure Help Topics](./AzureHelpTopics.md) for more Information on how to retrieve those values.

## Using a Managed Identity to authenticate with Terraform

To authenticate to Terraform when running on an Azure VM with a Managed Identity, you will need to set the following three terraform variables:

| Name | Description | Type | Notes |
| :--- | ---: | ---: | ---: |
| tenant_id | your Azure tenant id | string  |
| subscription_id | your Azure subscription id | string  |
| use_msi | use the Managed Identity of your Azure VM | bool | true |

## How to set the Terraform Authentication variables

We recommend to use environment variables to pass the authentication information into your terraform job.

You can use the `TF_VAR_` prefix to set your terraform variables as environment variables.

### Set Authentication Variables when running Terraform directly

Run these commands to initialize the environment for the project. These commands will need to be run and pulled  into your environment each time you start a new session to use this repo and terraform.

Example for using a Service Principal:

```bash
# export needed ids and secrets
export TF_VAR_subscription_id="00000000-0000-0000-0000-000000000000"
export TF_VAR_tenant_id="00000000-0000-0000-0000-000000000000"
export TF_VAR_client_id="00000000-0000-0000-0000-000000000000"
export TF_VAR_client_secret="00000000-0000-0000-0000-000000000000"
```

**TIP:** These commands can be stored in a file outside of this repo in a secure file.
Use your favorite editor, take the content above and save it to a file called:
`$HOME/.azure_creds.sh` . (Protect that file so only you have read access to it.) Now each time you need these values you can do the following:

```bash
source $HOME/.azure_creds.sh
```

This will pull in those values into your current terminal session. Any terraform commands submitted in that session will use those values.

### Set Authentication Variables when using the Docker container

When using the docker container to run terraform, ru these commands to initialize the environment for the project. These commands will need to be run and pulled into your environment each time you start a new terminal session.

Example for using a Managed Identity:

```
# Needed ids and secrets for docker
TF_VAR_subscription_id="00000000-0000-0000-0000-000000000000"
TF_VAR_tenant_id= "00000000-0000-0000-0000-000000000000"
TF_VAR_use_msi="true"
```

**TIP:** These commands can be stored in a file outside of this repo in a secure file.
Use your favorite editor, take the content above and save it to a file called:
`$HOME/.azure_docker_creds.env` . (Protect that file so only you have read access to it.) Now each time you need these values you can do the following:

Then use the file in the `--env-file` docker option

```bash
docker <...> \
  --env-file $HOME/.azure_docker_creds.env \
  <...>
```


