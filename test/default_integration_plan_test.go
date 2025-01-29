package test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	tfjson "github.com/hashicorp/terraform-json"
	"github.com/stretchr/testify/assert"
)

type NodePool struct {
	Name        string
	MachineType string
	OsDiskSize  float64
	MinNodes    float64
	MaxNodes    float64
	MaxPods     float64
	NodeTaints  []string
	NodeLabels  map[string]string
}

func TestGeneral(t *testing.T) {
	t.Parallel()

	uniquePrefix := strings.ToLower(random.UniqueId())
	p := "../examples/sample-input-defaults.tfvars"

	var variables map[string]interface{}
	terraform.GetAllVariablesFromVarFile(t, p, &variables)

	//  add the required variables
	variables["prefix"] = "terratest-" + uniquePrefix
	variables["location"] = "eastus2"
	variables["default_public_access_cidrs"] = strings.Split(os.Getenv("TF_VAR_public_cidrs"), ",")

	// Create a temporary file in the default temp directory
	planFileName := "testplan-" + uniquePrefix + ".tfplan"
	planFilePath := filepath.Join("/tmp/", planFileName)
	defer os.Remove(planFilePath) // Ensure file is removed on exit
	os.Create(planFilePath)

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located.
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options.
		Vars: variables,

		// Configure a plan file path so we can introspect the plan and make assertions about it.
		PlanFilePath: planFilePath,

		NoColor: true,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]

	// partner_id - Not present in tfplan

	// create_static_kubeconfig - Not present in tfplan

	// kubernetes_version
	k8sVersion := cluster.AttributeValues["kubernetes_version"]
	assert.Equal(t, "1.30", k8sVersion, "Unexpected Kubernetes version")

	// create_jump_vm
	// Verify that the jump vm has been created
	jumpVM := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_linux_virtual_machine.vm"]
	assert.NotNil(t, jumpVM, "Jump VM should be created")

	// create_jump_public_ip
	jumpPublicIP := plan.ResourcePlannedValuesMap["module.jump[0].azurerm_public_ip.vm_ip[0]"]
	assert.NotNil(t, jumpPublicIP, "Jump VM public IP should exist")

	// enable_jump_public_static_ip
	assert.Equal(t, "Static", jumpPublicIP.AttributeValues["allocation_method"], "Jump VM should use static IP")

	// jump_vm_admin
	assert.Equal(t, "jumpuser", jumpVM.AttributeValues["admin_username"], "Unexpected jump VM admin username")

	// jump_vm_machine_type
	assert.Equal(t, "Standard_B2s", jumpVM.AttributeValues["size"], "Unexpected jump VM machine type")

	// jump_rwx_filestore_path - in the output but not the tfplan?

	// tags - defaults to empty so there is nothing to test. If we wanted to test it, this is how we would
	// aksTags := cluster.AttributeValues["tags"]
	// assert.Equal(t, aksTags, map[string]interface{}(map[string]interface{}{"test": "test"}), "Unexpected AKS Tags")

	// aks_identity
	userAssignedIdentity := plan.ResourcePlannedValuesMap["azurerm_user_assigned_identity.uai[0]"]
	assert.NotNil(t, userAssignedIdentity, "The User Identity should exist.")

	// ssh_public_key
	assert.True(t, testSSHKey(t, cluster), "SSH Key should exist")

	// cluster_api_mode - in the output but not the tfplan

	// aks_cluster_private_dns_zone_id - defaults to empty, only known after apply

	// aks_cluster_sku_tier
	skuTier := cluster.AttributeValues["sku_tier"]
	assert.Equal(t, skuTier, "Free", "Unexpected aks_cluster_sku_tier")

	// cluster_support_tier
	supportPlan := cluster.AttributeValues["support_plan"]
	assert.Equal(t, supportPlan, "KubernetesOfficial", "Unexpected cluster_support_tier")

	/* Additional Node Pools */
	statelessNodePool := plan.ResourcePlannedValuesMap["module.node_pools[\"stateless\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"]
	statelessStruct := NodePool{
		MachineType: "Standard_D4s_v5",
		OsDiskSize:  200,
		MinNodes:    0,
		MaxNodes:    5,
		MaxPods:     110,
		NodeTaints:  []string{"workload.sas.com/class=stateless:NoSchedule"},
		NodeLabels: map[string]string{
			"workload.sas.com/class": "stateless",
		},
	}
	testNodePools(t, statelessNodePool, statelessStruct)

	statefulNodePool := plan.ResourcePlannedValuesMap["module.node_pools[\"stateful\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"]
	statefulStruct := NodePool{
		MachineType: "Standard_D4s_v5",
		OsDiskSize:  200,
		MinNodes:    0,
		MaxNodes:    3,
		MaxPods:     110,
	}
	testNodePools(t, statefulNodePool, statefulStruct)

	casNodePool := plan.ResourcePlannedValuesMap["module.node_pools[\"cas\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"]
	casStruct := NodePool{
		MachineType: "Standard_E16ds_v5",
		OsDiskSize:  200,
		MinNodes:    0,
		MaxNodes:    5,
		MaxPods:     110,
	}
	testNodePools(t, casNodePool, casStruct)

	computeNodePool := plan.ResourcePlannedValuesMap["module.node_pools[\"compute\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"]
	computeStruct := NodePool{
		MachineType: "Standard_D4ds_v5",
		OsDiskSize:  200,
		MinNodes:    1,
		MaxNodes:    5,
		MaxPods:     110,
	}
	testNodePools(t, computeNodePool, computeStruct)
}

func testSSHKey(t *testing.T, cluster *tfjson.StateResource) bool {
	// Get the linux profile object and cast it to map[string]interface{}
	linuxProfile, ok := cluster.AttributeValues["linux_profile"].([]interface{})[0].(map[string]interface{})
	if !ok {
		t.Log("linux_profile not found in cluster resources. Failing test")
		return false
	}
	// Get the ssh_key object and cast it to interface{}(string)
	keyData, ok := linuxProfile["ssh_key"].([]interface{})[0].(map[string]interface{})["key_data"]
	if !ok {
		t.Log("ssh_key not found in linux_profile. Failing test")
		return false
	}
	// Finally cast the key to a string and verify that it is not empty
	key, ok := keyData.(string)
	if !ok {
		t.Log("Raw ssh key not found in ssh_key object. Failing test")
		return false
	}
	return key != ""
}

func testNodePools(t *testing.T, nodePool *tfjson.StateResource, expectedValues NodePool) {
	// machine_type
	assert.Equal(t, expectedValues.MachineType, nodePool.AttributeValues["vm_size"], "Unexpected machine_type.")

	// os_disk_size
	assert.Equal(t, expectedValues.OsDiskSize, nodePool.AttributeValues["os_disk_size_gb"], "Unexpected os_disk_size.")

	// min_nodes
	assert.Equal(t, expectedValues.MinNodes, nodePool.AttributeValues["min_count"], "Unexpected min_nodes.")

	// max_nodes
	assert.Equal(t, expectedValues.MaxNodes, nodePool.AttributeValues["max_count"], "Unexpected max_nodes.")

	// max_pods
	assert.Equal(t, expectedValues.MaxPods, nodePool.AttributeValues["max_pods"], "Unexpected max_pods.")

	// node_taints
	for index, nodeTaint := range expectedValues.NodeTaints {
		assert.Equal(t, nodeTaint, nodePool.AttributeValues["node_taints"].([]interface{})[index].(string), "Unexpected Node Taints")
	}

	// node_labels
	// TODO
	assert.Equal(t, expectedValues.NodeLabels, nodePool.AttributeValues["node_labels"], "Unexpected Node Labels")

	// node_pools_availability_zone

	// node_pools_proximity_placement

}
