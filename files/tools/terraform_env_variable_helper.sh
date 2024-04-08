#!/usr/bin/env bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

echo -e "\nUsage: You must have an active az cli login 'az login' before this script will work"
echo -e "\nUsage: Run an export referenced in line 8 or 9 before this script before continuing"
echo "    For example: export YOURSP=your-SP-name or export YOURSP=\$USER"
echo -e "\nUsage: source ./<path-to-file>TerraformEnvVariableAssignment.sh; e.g. source ./files/tools/terraform_env_variable_helper.sh"
echo -e "\nUsage: The variable \$YOURSP needs to be set and currently has a value of Service Principal: >>>>> $YOURSP <<<<<"

if [[ -z "${YOURSP}" ]]; then
  echo -e "***\nThe variable \$YOURSP needs to be set before this script can continue, see usage notes\n***" 1>&2
  exit
fi

# `set -e` is used below to ensure that all of the assignments in the script are made / that it runs in entirety
set -e
echo -e "***\nPausing for 7 seconds so you can review; use ctrl-c to exit and resolve\n***"
sleep 7s

# set the tenant ID from a query; validate
TF_VAR_tenant_id=$(az account show --query 'tenantId' --output tsv)
export TF_VAR_tenant_id
echo -e "\nTF_VAR_tenant_id:"
echo -e "$TF_VAR_tenant_id"

# set the subscription Name from a query; validate
TF_VAR_subscription_name=$(az account show --query 'name' --output tsv)
export TF_VAR_subscription_name
echo -e "\nTF_VAR_subscription_name:"
echo -e "$TF_VAR_subscription_name"

# set the subscription ID from a query; validate
TF_VAR_subscription_id=$(az account show --query 'id' --output tsv)
export TF_VAR_subscription_id
echo -e "\nTF_VAR_subscription_id:"
echo -e "$TF_VAR_subscription_id"

# obtain the client ID
TF_VAR_client_id=$(az ad sp list --display-name "$YOURSP" --query '[].appId' --output tsv)
export TF_VAR_client_id
echo -e "\nTF_VAR_client_id for this Service Principal $YOURSP:"
echo -e "$TF_VAR_client_id"

# obtain a client secret
TF_VAR_client_secret=$(az ad sp create-for-rbac --skip-assignment --name "$YOURSP" --query password --output tsv)
export TF_VAR_client_secret
echo -e "\nTF_VAR_client_secret:"
echo -e "$TF_VAR_client_secret"

# `set +e` reverses the `set -e`
set +e

echo -e "\nAll done"
echo -e "\nIf the wrong subscription was selected, then suggest:"
echo -e "   \$az account list --output table"
echo -e "   \$az account set --subscription <YourSubscription>"

echo -e "\nIf the azurerm module is returning an http/401 error, then you might want to reset your SP credential:"
echo -e "   \$az ad sp credential reset --name $YOURSP"