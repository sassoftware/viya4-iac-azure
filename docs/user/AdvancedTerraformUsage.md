
# Advanced Terraform Usage

## Terraform - Plan

Once the Terraform project has been initialized, you can run the ```terraform plan``` command to generate a plan file. You can then review the plan before running ```terraform apply```, the command that actually creates cloud resources. Use the plan in order to:

- verify that the Terraform script runs with no errors
- review the cloud resources and dependencies before creating them
- find any disparities between local definitions and the actual infrastructure. To find these differences, run the command after the infrastructure has been created with `terraform apply`.

Terraform accepts inputs and will prompt you for them. However, you can also pass them in from the command line using the ```-var``` or ```-var-file``` options.
Passing them in this way overrides any default values in ```variables.tf```.

```bash
# to generate a terraform plan
terraform plan -var-file=sample-input.tfvars -out ./my-viya4-iac.plan
```

## Terraform - Show

Run the ```terraform show``` command to display the plan file again.

```bash
# to review the plan
terraform show my-viya4-iac.plan
```

## Terraform - Apply

After any errors are resolved and you are satisfied with the plan, run the ```terraform apply``` command to create resources on the cloud provider. When a plan file is not provided, Terraform generates a plan at that time that might differ from previous ```plan``` runs.

```bash
# run apply to create resources based on the plan
terraform apply ./my-viya4-iac.plan
```

## Terraform - State

After the resources have been created, use ```terraform state list``` to list all the resources and ```terraform state show``` to get detailed information about a resource.

```bash
terraform state list
# to get more details on a particular resource
terraform state show <resource-name-from-state-list>
```
If you decide to use the [viya4-deployment project](https://github.com/sassoftware/viya4-deployment), which uses Ansible to complete the configuration of your cluster to meet SAS Viya requirements, you can provide the tfstate file to enable auto-discovery of the kubeconfig file and other settings.

## Terraform - Output

To display Terraform output, use the `terraform output` command to show all output or a specific output variable.

```bash
terraform output
# to get the value of a specific output variable
terraform output <output-variable>
```
