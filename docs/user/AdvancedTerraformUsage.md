
# Advanced Terraform Usage

## Terraform - Plan

Once Terraform project is initialized, ```terraform plan``` command can be run multiple times to generate a plan to review prior to running ```terraform apply``` that actually creating cloud resources. This is helpful to 
1) verify that the Terraform script runs with no errors
2) review the cloud resources and dependencies before creating them
3) when run after infrastructure has been created with '*terraform apply*' it diffs between the local definitions and the actual infrastructure 

Terraform accepts inputs when prompted or you can conveniently pass them into the command line with ```-var``` or ```-var-file``` options. This overrides any default values in ```variables.tf```

```
# to generate a terraform plan
terraform plan -var-file=sample-input.tfvars -out ./my-viya4-iac.plan
```

## Terraform - Show

Run ```terraform show``` command to display the plan again

    # to review the plan
    terraform show my-viya4-iac.plan

## Terraform - Apply

After any errors are resolved and satisfied with the plan, run the ```terraform apply``` command to create resources on the cloud provider. When a plan file is not provided, Terraform generates a plan at that time that may differ from previous ```plan``` runs.  

    # run apply to create resources based on the plan
    terraform apply ./my-viya4-iac.plan

## Terraform - State

After the resouces are created use ```terraform state list``` to list all the resources and ```terraform state show``` to get details of a resource.

    terraform state list 
    # to get more details on a partictular resource 
    terraform state show <resource-name-from-state-list>

## Terraform - Output

To display the outputs captured by terraform you can use the `terraform output` command to show all or a specific output variable.

    terraform output
    # to get the value of a specific output variable
    terraform output <output-variable>

