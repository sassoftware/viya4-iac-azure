# usage: source <path-to-file>TerraformEnvVariableAssignment.sh

echo -e "You must have an active az cli login 'az login' before this script will work"
echo -e "\nPausing for 5 seconds; use ctrl-c to exit and login"
sleep 5s

# set the tenant ID from a query; validate
export TF_VAR_tenant_id=$(az account show --query 'tenantId' --output tsv)
echo -e "\nTF_VAR_tenant_id:"
echo -e $TF_VAR_tenant_id

# set the subscription ID from a query; validate
export TF_VAR_subscription_id=$(az account show --query 'id' --output tsv)
echo -e "\nTF_VAR_subscription_id:"
echo -e $TF_VAR_subscription_id

export TF_VAR_client_secret=$(az ad sp create-for-rbac --skip-assignment --name http://$USER --query password --output tsv)
echo -e "\nTF_VAR_client_secret:"
echo -e $TF_VAR_client_secret

export TF_VAR_client_id=$(az ad sp show --id http://$USER --query appId --output tsv)
echo -e "\nTF_VAR_client_id:"
echo -e $TF_VAR_client_id

echo -e "\nAll done"
