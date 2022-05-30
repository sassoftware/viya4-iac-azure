
#!/bin/bash

export storage_account="ecdeploy"
export TF_VAR_ENV="SHD"
export TF_VAR_COMPONENT="SAS"
export TF_VAR_VERSION="1.0.0"

STATUS=0

if [ "$1" == "-init" ]; then
    rm -rf .terraform
    terragrunt init
    terragrunt get
fi

if [ "$1" == "-plan" ]; then
  echo "----------------------------------------------------"
  echo "| ${GREEN} Running terraform plan ... ${RESET}"
  echo "----------------------------------------------------"         
  terragrunt plan -var-file=./envs/nonprod/input.tfvars -detailed-exitcode
  STATUS=$?
fi

if [ "$1" == "-apply" ]; then
    echo "----------------------------------------------------"
    echo "| ${GREEN} Running terraform apply ... ${RESET}"
    echo "----------------------------------------------------"         
    terragrunt apply -var-file=./envs/nonprod/input.tfvars
    STATUS=$?
fi

# Useful for Automation clients
if [ "$1" == "-planapply" ]; then
  echo "----------------------------------------------------"
  echo "| ${GREEN} Running terraform plan ... ${RESET}"
  echo "----------------------------------------------------"         
  terragrunt plan -var-file=./envs/nonprod/input.tfvars -detailed-exitcode
  STATUS=$?

  if [ $STATUS -eq 0 ]; then
    echo "No changes detected, not applying."
  elif [ $STATUS -eq 1 ]; then
    echo "Terraform plan failed."
    exit 1
  elif [ $STATUS -eq 2 ]; then
    echo "Changes detected. Applying..."
    terragrunt apply -var-file=./envs/nonprod/input.tfvars -auto-approve
  fi
fi
