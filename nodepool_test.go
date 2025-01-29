package test

import (
"testing"

"github.com/gruntwork-io/terratest/modules/terraform"
"github.com/stretchr/testify/assert"
)

func TestNodePoolsVariables(t *testing.T) {
t.Parallel()

// Define Terraform options
terraformOptions := &terraform.Options{
// Path to the directory containing Terraform code
TerraformDir: "<Add your terraform directory path>", 
}

// Run terraform init and terraform plan
terraform.InitAndPlan(t, terraformOptions) 

// Fetch Terraform outputs
nodeVmAdmin := terraform.Output(t, terraformOptions, "node_vm_admin")
nodePoolVmType := terraform.Output(t, terraformOptions, "default_nodepool_vm_type")
nodePoolDiskSize := terraform.Output(t, terraformOptions, "default_nodepool_os_disk_size")
nodePoolMaxPods := terraform.Output(t, terraformOptions, "default_nodepool_max_pods")
nodePoolMinNodes := terraform.Output(t, terraformOptions, "default_nodepool_min_nodes")
nodePoolMaxNodes := terraform.Output(t, terraformOptions, "default_nodepool_max_nodes")
nodePoolAvailabilityZones := terraform.OutputList(t, terraformOptions, "default_nodepool_availability_zones")

// Assertions to validate Terraform outputs
assert.Equal(t, "azureuser", nodeVmAdmin, "node_vm_admin should be 'azureuser'")
assert.Equal(t, "Standard_E8s_v5", nodePoolVmType, "default_nodepool_vm_type should be 'Standard_E8s_v5'")
assert.Equal(t, "128", nodePoolDiskSize, "default_nodepool_os_disk_size should be '128'")
assert.Equal(t, "110", nodePoolMaxPods, "default_nodepool_max_pods should be '110'")
assert.Equal(t, "1", nodePoolMinNodes, "default_nodepool_min_nodes should be '1'")
assert.Equal(t, "5", nodePoolMaxNodes, "default_nodepool_max_nodes should be '5'")
assert.Equal(t, []string{"1"}, nodePoolAvailabilityZones, "default_nodepool_availability_zones should be ['1']")
}