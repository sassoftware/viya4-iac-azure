//go:build integration_plan_unit_tests

package test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	tfjson "github.com/hashicorp/terraform-json"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type NodePool struct {
	Name              string
	MachineType       string
	OsDiskSize        float64
	MinNodes          float64
	MaxNodes          float64
	MaxPods           float64
	NodeTaints        []string
	NodeLabels        map[string]string
	AvailabilityZones []string
	FipsEnabled       bool
}

type Subnet struct {
	prefixes                                 []interface{}
	serviceEndpoints                         []interface{}
	privateEndpointNetworkPolicies           string
	privateLinkServiceNetworkPoliciesEnabled bool
	serviceDelegations                       map[string]interface{}
}

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestDefaults(t *testing.T) {
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
	planFilePath := filepath.Join(os.TempDir(), planFileName)
	_, err := os.Create(planFilePath)
	require.NoError(t, err)
	defer os.Remove(planFilePath) // Ensure file is removed on exit

	// Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located.
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options.
		Vars: variables,

		// Configure a plan file path so we can introspect the plan and make assertions about it.
		PlanFilePath: planFilePath,

		// Remove color codes to clean up output
		NoColor: true,
	}

	plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]

	// vnet_address_space
	expectedVnetAddress := []interface{}{"192.168.0.0/16"}
	vnetResource := plan.ResourcePlannedValuesMap["module.vnet.azurerm_virtual_network.vnet[0]"]
	vnetAttributes := vnetResource.AttributeValues["address_space"].([]interface{})
	assert.Equal(t, expectedVnetAddress, vnetAttributes)

	// aks Subnets
	expectedAKSSubnet := &Subnet{
		prefixes:                                 []interface{}{"192.168.0.0/23"},
		serviceEndpoints:                         []interface{}{"Microsoft.Sql"},
		privateEndpointNetworkPolicies:           "Disabled",
		privateLinkServiceNetworkPoliciesEnabled: false,
		serviceDelegations:                       nil,
	}
	verifySubnets(t, plan.ResourcePlannedValuesMap["module.vnet.azurerm_subnet.subnet[\"aks\"]"], expectedAKSSubnet)

	// misc subnet
	expectedMiscSubnet := &Subnet{
		prefixes:                                 []interface{}{"192.168.2.0/24"},
		serviceEndpoints:                         []interface{}{"Microsoft.Sql"},
		privateEndpointNetworkPolicies:           "Disabled",
		privateLinkServiceNetworkPoliciesEnabled: false,
		serviceDelegations:                       nil,
	}
	verifySubnets(t, plan.ResourcePlannedValuesMap["module.vnet.azurerm_subnet.subnet[\"misc\"]"], expectedMiscSubnet)

	// cluster_egress_type
	var expectedClusterEgressType interface{} = "loadBalancer"
	egressType := cluster.AttributeValues["network_profile"]
	actualEgressType := egressType.([]interface{})[0].(map[string]interface{})["outbound_type"]
	assert.Equal(t, expectedClusterEgressType, actualEgressType, "Unexpected Cluster Egress Type")

	//aks_network_plugin
	var expectedNetworkPlugin interface{} = "kubenet"
	networkPlugin := cluster.AttributeValues["network_profile"]
	actualNetworkPlugin := networkPlugin.([]interface{})[0].(map[string]interface{})["network_plugin"]
	assert.Equal(t, expectedNetworkPlugin, actualNetworkPlugin, "Unexpected Network Plugin")

	// aks_network_policy cannot be tested since it is set after the apply.
	/*var expectedNetworkPolicy interface{} = "calico"
	networkPolicy := cluster.AttributeValues["network_profile"]
	actualNetworkPolicy := networkPolicy.([]interface{})[0].(map[string]interface{})["network_policy"]
	assert.Equal(t, expectedNetworkPolicy, actualNetworkPolicy, "Unexpected Network Policy")

	// aks_network_plugin_mode this cannot be tested since it defaults to null
	/*var expectedNetworkPluginMode interface{} = "overlay"
	networkPluginMode := cluster.AttributeValues["network_profile"]
	actualNetworkPluginMode := networkPluginMode.([]interface{})[0].(map[string]interface{})["network_plugin_mode"]
	assert.Equal(t, expectedNetworkPluginMode, actualNetworkPluginMode, "Unexpected Network Plugin Mode") */

	// partner_id - Not present in tfplan

	// create_static_kubeconfig
	// Assert that the Cluster Role Binding and Service Account objects
	// are present in the output. create_static_kubeconfig=false would
	// not contain these objects.
	kubeconfigCRBResource := plan.ResourcePlannedValuesMap["module.kubeconfig.kubernetes_cluster_role_binding.kubernetes_crb[0]"]
	assert.NotNil(t, kubeconfigCRBResource, "Kubeconfig CRB object should not be nil")
	kubeconfigSAResource := plan.ResourcePlannedValuesMap["module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]"]
	assert.NotNil(t, kubeconfigSAResource, "Kubeconfig Service Account object should not be nil")

	// kubernetes_version
	k8sVersion := cluster.AttributeValues["kubernetes_version"]
	assert.Equal(t, "1.30", k8sVersion, "Unexpected Kubernetes version")

	// create_jump_vm
	// Verify that the jump vm resource is not nil
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

	// jump_rwx_filestore_path
	assert.Equal(t, "/viya-share", plan.RawPlan.OutputChanges["jump_rwx_filestore_path"].After.(string))

	// prefix
	assert.Equal(t, variables["prefix"], plan.RawPlan.OutputChanges["prefix"].After.(string))

	// location
	// module.aks.data.azurerm_public_ip.cluster_public_ip[0] location is set after apply.
	locationResources := []string{
		"azurerm_network_security_group.nsg[0]",
		"azurerm_resource_group.aks_rg[0]",
		"azurerm_user_assigned_identity.uai[0]",
		"module.aks.azurerm_kubernetes_cluster.aks",
		"module.jump[0].azurerm_linux_virtual_machine.vm",
		"module.jump[0].azurerm_network_interface.vm_nic",
		"module.jump[0].azurerm_public_ip.vm_ip[0]",
		"module.nfs[0].azurerm_linux_virtual_machine.vm",
		"module.nfs[0].azurerm_managed_disk.vm_data_disk[0]",
		"module.nfs[0].azurerm_managed_disk.vm_data_disk[1]",
		"module.nfs[0].azurerm_managed_disk.vm_data_disk[2]",
		"module.nfs[0].azurerm_managed_disk.vm_data_disk[3]",
		"module.nfs[0].azurerm_network_interface.vm_nic",
		"module.vnet.azurerm_virtual_network.vnet[0]",
	}
	for _, value := range locationResources {
		locationResource := plan.ResourcePlannedValuesMap[value]
		locationAttributes := locationResource.AttributeValues["location"]
		assert.Equal(t, variables["location"], locationAttributes, "Unexpected location")
	}
	assert.Equal(t, variables["location"], plan.RawPlan.OutputChanges["location"].After.(string), "Unexpected location")

	// tags - defaults to empty so there is nothing to test. If we wanted to test it, this is how we would
	// aksTags := cluster.AttributeValues["tags"]
	// assert.Equal(t, aksTags, map[string]interface{}(map[string]interface{}{"test": "test"}), "Unexpected AKS Tags")

	// aks_identity
	userAssignedIdentity := plan.ResourcePlannedValuesMap["azurerm_user_assigned_identity.uai[0]"]
	assert.NotNil(t, userAssignedIdentity, "The User Identity should exist.")

	// ssh_public_key
	assert.True(t, testSSHKey(t, cluster), "SSH Key should exist")

	// cluster_api_mode
	assert.Equal(t, "public", plan.RawPlan.OutputChanges["cluster_api_mode"].After.(string))

	// aks_cluster_private_dns_zone_id - defaults to empty, only known after apply

	// aks_cluster_sku_tier
	skuTier := cluster.AttributeValues["sku_tier"]
	assert.Equal(t, skuTier, "Free", "Unexpected aks_cluster_sku_tier")

	// cluster_support_tier
	supportPlan := cluster.AttributeValues["support_plan"]
	assert.Equal(t, supportPlan, "KubernetesOfficial", "Unexpected cluster_support_tier")

	// Additional Node Pools
	statelessNodePool := plan.ResourcePlannedValuesMap["module.node_pools[\"stateless\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"]
	statelessStruct := &NodePool{
		MachineType: "Standard_D4s_v5",
		OsDiskSize:  200,
		MinNodes:    0,
		MaxNodes:    5,
		MaxPods:     110,
		NodeTaints:  []string{"workload.sas.com/class=stateless:NoSchedule"},
		NodeLabels: map[string]string{
			"workload.sas.com/class": "stateless",
		},
		AvailabilityZones: []string{"1"},
		FipsEnabled:       false,
	}
	verifyNodePools(t, statelessNodePool, statelessStruct)

	statefulNodePool := plan.ResourcePlannedValuesMap["module.node_pools[\"stateful\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"]
	statefulStruct := &NodePool{
		MachineType: "Standard_D4s_v5",
		OsDiskSize:  200,
		MinNodes:    0,
		MaxNodes:    3,
		MaxPods:     110,
		NodeTaints:  []string{"workload.sas.com/class=stateful:NoSchedule"},
		NodeLabels: map[string]string{
			"workload.sas.com/class": "stateful",
		},
		AvailabilityZones: []string{"1"},
		FipsEnabled:       false,
	}
	verifyNodePools(t, statefulNodePool, statefulStruct)
	casNodePool := plan.ResourcePlannedValuesMap["module.node_pools[\"cas\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"]
	casStruct := &NodePool{
		MachineType: "Standard_E16ds_v5",
		OsDiskSize:  200,
		MinNodes:    0,
		MaxNodes:    5,
		MaxPods:     110,
		NodeTaints:  []string{"workload.sas.com/class=cas:NoSchedule"},
		NodeLabels: map[string]string{
			"workload.sas.com/class": "cas",
		},
		AvailabilityZones: []string{"1"},
		FipsEnabled:       false,
	}
	verifyNodePools(t, casNodePool, casStruct)

	computeNodePool := plan.ResourcePlannedValuesMap["module.node_pools[\"compute\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]"]
	computeStruct := &NodePool{
		MachineType: "Standard_D4ds_v5",
		OsDiskSize:  200,
		MinNodes:    1,
		MaxNodes:    5,
		MaxPods:     110,
		NodeTaints:  []string{"workload.sas.com/class=compute:NoSchedule"},
		NodeLabels: map[string]string{
			"workload.sas.com/class":        "compute",
			"launcher.sas.com/prepullImage": "sas-programming-environment",
		},
		AvailabilityZones: []string{"1"},
		FipsEnabled:       false,
	}
	verifyNodePools(t, computeNodePool, computeStruct)

	// storage_type
	// when storage_type is standard, we should have nfs stuff
	// make sure module.nfs[0].azurerm_linux_virtual_machine.vm exists
	nfsVM := plan.ResourcePlannedValuesMap["module.nfs[0].azurerm_linux_virtual_machine.vm"]
	assert.NotNil(t, nfsVM, "NFS VM should be created")
	assert.Equal(t, "nfsuser", nfsVM.AttributeValues["admin_username"], "Unexpected NFS Admin Username")
	assert.Equal(t, "Standard_D4s_v5", nfsVM.AttributeValues["size"], "Unexpected NFS VM Size")

	// create_nfs_public_ip
	nfsPublicIP := plan.ResourcePlannedValuesMap["module.nfs[0].azurerm_public_ip.vm_ip[0]"]
	assert.Nil(t, nfsPublicIP, "NFS Public IP should not be created when create_nfs_public_ip=false")

	// enable_nfs_public_static_ip
	// only used with create_nfs_public_ip=true

	// aks
	aks := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]
	aad_rbac := aks.AttributeValues["azure_active_directory_role_based_access_control"]
	assert.Empty(t, aad_rbac, "Unexpected azure_active_directory_role_based_access_control; should be empty by default")
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

func verifyNodePools(t *testing.T, nodePool *tfjson.StateResource, expectedValues *NodePool) {
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
	nodeLabelsStatus := true
	nodeLabels := nodePool.AttributeValues["node_labels"]
	// Convert the interface {}(map[string]interface {}) to JSON string
	j, err := json.Marshal(nodeLabels)
	if err != nil {
		t.Log("Error parsing tfplan's Node Labels: ", err)
		nodeLabelsStatus = false
	}
	// Unmarshal the JSON string into the map
	var result map[string]string
	err = json.Unmarshal(j, &result)
	if err != nil {
		t.Log("Error unmarshaling Node Labels Json string: ", err)
		nodeLabelsStatus = false
	}
	// If no previous errors, verify that the maps are equal
	if nodeLabelsStatus {
		assert.True(t, reflect.DeepEqual(expectedValues.NodeLabels, result), "Unexpected Node Labels")
	} else {
		assert.Fail(t, "Unexpected errors parsing Node Labels")
	}

	// node_pools_availability_zone
	for index, az := range expectedValues.AvailabilityZones {
		assert.Equal(t, az, nodePool.AttributeValues["zones"].([]interface{})[index].(string), "Unexpected Availability Zones")
	}

	// fips_enabled
	assert.Equal(t, expectedValues.FipsEnabled, nodePool.AttributeValues["fips_enabled"], "Unexpected fips_enabled.")

	// node_pools_proximity_placement - Can't find in tfplan

}

// Subnet func
func verifySubnets(t *testing.T, subnet *tfjson.StateResource, expectedValues *Subnet) {
	// prefixes
	assert.Equal(t, expectedValues.prefixes, subnet.AttributeValues["address_prefixes"], "Unexpected Subnet address_prefixes")

	// service_endpoints
	assert.Equal(t, expectedValues.serviceEndpoints, subnet.AttributeValues["service_endpoints"], "Unexpected Subnet service endpoints")

	// private_endpoint_network_policies
	// TODO figure out why these don't match the expected
	// assert.Equal(t, expectedValues.privateEndpointNetworkPolicies, subnet.AttributeValues["private_endpoint_network_policies"], "Unexpected private_endpoint_network_policies")

	// private_link_service_network_policies_enabled
	assert.Equal(t, expectedValues.privateLinkServiceNetworkPoliciesEnabled, subnet.AttributeValues["private_link_service_network_policies_enabled"], "Unexpected private_link_service_network_policies_enabled")

	// service_delegations
	// If no sevice_delegations are set, verify that there is no service_delegations
	// attribute in the resource. Otherwise, check that the attribute matches the expected
	if expectedValues.serviceDelegations == nil {
		assert.Nil(t, subnet.AttributeValues["service_delegations"], "Service delegations should be nil")
	} else {
		assert.Equal(t, expectedValues.serviceDelegations, subnet.AttributeValues["service_delegations"], "Unexpected service delegations")
	}
}
