#!/usr/bin/env bash
set -e

# usage: source <path-to-file>TerraformEnvVariableAssignment.sh
# usage: you must comment / uncomment one of rows 3-4
export YourSP="MTES_Customer_Advisory_SP"
#export YourSP=$USER

echo -e "You must have an active az cli login 'az login' before this script will work"
echo -e "We will use the Service Principal for >>>>> $YourSP <<<<<"
echo -e "Otherwise comment line 23, uncomment 24, and edit 6 to use the following"
echo -e "\nPausing for 5 seconds; use ctrl-c to exit and login"
sleep 5s

# set the tenant ID from a query; validate
export TF_VAR_tenant_id=$(az account show --query 'tenantId' --output tsv)
echo -e "\nTF_VAR_tenant_id:"
echo -e $TF_VAR_tenant_id

# set the subscription Name from a query; validate
export TF_VAR_subscription_name=$(az account show --query 'name' --output tsv)
echo -e "\nTF_VAR_subscription_name:"
echo -e $TF_VAR_subscription_name

# set the subscription ID from a query; validate
export TF_VAR_subscription_id=$(az account show --query 'id' --output tsv)
echo -e "\nTF_VAR_subscription_id:"
echo -e $TF_VAR_subscription_id

# obtain the client ID
export TF_VAR_client_id=$(az ad sp show --id http://$YourSP --query appId --output tsv)
echo -e "\nTF_VAR_client_id for this Service Principal $YourSP:"
echo -e $TF_VAR_client_id

# obtain a client secret
export TF_VAR_client_secret=$(az ad sp create-for-rbac --skip-assignment --name http://$YourSP --query password --output tsv)
echo -e "\nTF_VAR_client_secret:"
echo -e $TF_VAR_client_secret

echo -e "\nAll done"
echo -e "\nIf the wrong subscription was selected, then suggest:"
echo -e "   \$az account list --output table"
echo -e "   \$az account set --subscription <YourSubscription>"
