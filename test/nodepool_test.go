package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestNodeVMAdmin(t *testing.T) {
	t.Parallel()

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	assert.NoError(t, err)

	cluster := plan.ResourcePlannedValuesMap["module.aks.azurerm_kubernetes_cluster.aks"]

	// node_vm_admin
	expectedNodeVMAdmin := "azureuser"
	actualNodeVMAdmin, err := getJsonPathFromStateResource(t, cluster, "{$.linux_profile[0].admin_username}")
	assert.NoError(t, err)
	assert.Equal(t, expectedNodeVMAdmin, actualNodeVMAdmin, "Unexpected Node VM Admin User")

	//default_nodepool_vm_type
	expectedNodepoolVMType := "Standard_E8s_v5"
	actualNodepoolVMType, err := getJsonPathFromStateResource(t, cluster, "{$.default_node_pool[0].vm_size}")
	assert.NoError(t, err)
	assert.Equal(t, expectedNodepoolVMType, actualNodepoolVMType, "Unexpected Default Node Pool VM Type")

	//default_nodepool_os_disk_size
	expectedNodepoolOSDiskSize := "128"
	actualNodepoolOSDiskSize, err := getJsonPathFromStateResource(t, cluster, "{$.default_node_pool[0].os_disk_size_gb}")
	assert.NoError(t, err)
	assert.Equal(t, expectedNodepoolOSDiskSize, actualNodepoolOSDiskSize, "Unexpected Default Node Pool OS Disk Size")

	//default_nodepool_max_pods
	expectedNodepoolMaxPods := "110"
	actualNodepoolMaxPods, err := getJsonPathFromStateResource(t, cluster, "{$.default_node_pool[0].max_pods}")
	assert.NoError(t, err)
	assert.Equal(t, expectedNodepoolMaxPods, actualNodepoolMaxPods, "Unexpected Default Node Pool Max Pods")

	//default_nodepool_min_nodes
	expectedNodepoolMinNodes := "1"
	actualNodepoolMinNodes, err := getJsonPathFromStateResource(t, cluster, "{$.default_node_pool[0].min_count}")
	assert.NoError(t, err)
	assert.Equal(t, expectedNodepoolMinNodes, actualNodepoolMinNodes, "Unexpected Default Node Pool Min Nodes")

	//default_nodepool_max_nodes
	expectedNodepoolMaxNodes := "5"
	actualNodepoolMaxNodes, err := getJsonPathFromStateResource(t, cluster, "{$.default_node_pool[0].max_count}")
	assert.NoError(t, err)
	assert.Equal(t, expectedNodepoolMaxNodes, actualNodepoolMaxNodes, "Unexpected Default Node Pool Max Nodes")

	//default_nodepool_availability_zones
	expectedNodepoolAvailability := "1"
	actualNodepoolAvailability, err := getJsonPathFromStateResource(t, cluster, "{$.default_node_pool[0].zones[*]}")
	assert.NoError(t, err)
	assert.Equal(t, expectedNodepoolAvailability, actualNodepoolAvailability, "Unexpected Default Node Pool Zones")
}
