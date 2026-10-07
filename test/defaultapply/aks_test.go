// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultapply

import (
	"os"
	"strconv"
	"test/helpers"
	"testing"

	"github.com/Azure/azure-sdk-for-go/services/containerservice/mgmt/2019-11-01/containerservice"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testApplyAKSCluster(t *testing.T, plan *terraform.PlanStruct) {
	aksResourceMapName := "module.aks.azurerm_kubernetes_cluster.aks"
	clusterName := helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.name}")()
	resourceGroupName := helpers.RetrieveFromPlan(plan, "azurerm_resource_group.aks_rg[0]", "{$.name}")()

	cluster, err := azure.GetManagedClusterE(t, resourceGroupName, clusterName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error getting AKS cluster: %s\n", err)
		return
	}

	tests := map[string]helpers.ApplyTestCase{
		"aksClusterExistsTest": {
			Expected:        "nil",
			ActualRetriever: helpers.RetrieveFromStruct(cluster, "ID"),
			AssertFunction:  assert.NotEqual,
			Message:         "AKS cluster ID is nil",
		},
		"aksProvisioningStateTest": {
			Expected:        "Succeeded",
			ActualRetriever: helpers.RetrieveFromStruct(cluster, "ManagedClusterProperties", "ProvisioningState"),
			Message:         "AKS cluster is not in Succeeded state",
		},
		"aksNameTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.name}"),
			ActualRetriever:   helpers.RetrieveFromStruct(cluster, "Name"),
			Message:           "AKS cluster name does not match plan",
		},
		"aksLocationTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.location}"),
			ActualRetriever:   helpers.RetrieveFromStruct(cluster, "Location"),
			Message:           "AKS cluster location does not match plan",
		},
		"aksNodeResourceGroupTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.node_resource_group}"),
			ActualRetriever:   helpers.RetrieveFromStruct(cluster, "ManagedClusterProperties", "NodeResourceGroup"),
			Message:           "AKS node resource group does not match plan",
		},
		// Azure may normalize "1.35" → "1.35.x"; assert the plan version is a prefix of the live version
		"aksKubernetesVersionTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.kubernetes_version}"),
			ActualRetriever:   helpers.RetrieveFromStruct(cluster, "ManagedClusterProperties", "KubernetesVersion"),
			AssertFunction:    assert.Contains,
			Message:           "AKS kubernetes version does not match plan",
		},
	}

	helpers.RunApplyTests(t, tests)
	testAKSDefaultNodePool(t, plan, aksResourceMapName, cluster)
}

func testAKSDefaultNodePool(t *testing.T, plan *terraform.PlanStruct, aksResourceMapName string, cluster *containerservice.ManagedCluster) {
	if cluster.ManagedClusterProperties == nil || cluster.AgentPoolProfiles == nil {
		t.Error("AKS cluster agent pool profiles are nil")
		return
	}

	var systemPool *containerservice.ManagedClusterAgentPoolProfile
	for i := range *cluster.AgentPoolProfiles {
		pool := (*cluster.AgentPoolProfiles)[i]
		if pool.Name != nil && *pool.Name == "system" {
			systemPool = &(*cluster.AgentPoolProfiles)[i]
			break
		}
	}
	if systemPool == nil {
		t.Error("AKS default node pool 'system' not found in agent pool profiles")
		return
	}

	tests := map[string]helpers.ApplyTestCase{
		"aksDefaultPoolVMSizeTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.default_node_pool[0].vm_size}"),
			ActualRetriever:   helpers.RetrieveFromStruct(systemPool, "VMSize"),
			Message:           "AKS default node pool VM size does not match plan",
		},
		"aksDefaultPoolMaxPodsTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.default_node_pool[0].max_pods}"),
			ActualRetriever:   helpers.RetrieveFromStruct(systemPool, "MaxPods"),
			Message:           "AKS default node pool max pods does not match plan",
		},
		"aksDefaultPoolOsDiskSizeTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.default_node_pool[0].os_disk_size_gb}"),
			ActualRetriever:   helpers.RetrieveFromStruct(systemPool, "OsDiskSizeGB"),
			Message:           "AKS default node pool OS disk size does not match plan",
		},
	}

	helpers.RunApplyTests(t, tests)

	t.Run("aksDefaultPoolNodeCountRangeTest", func(t *testing.T) {
		minStr := helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.default_node_pool[0].min_count}")()
		maxStr := helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.default_node_pool[0].max_count}")()
		minCount, err := strconv.Atoi(minStr)
		if err != nil {
			t.Fatalf("failed to parse min_count '%s' from plan: %v", minStr, err)
		}
		maxCount, err := strconv.Atoi(maxStr)
		if err != nil {
			t.Fatalf("failed to parse max_count '%s' from plan: %v", maxStr, err)
		}
		if systemPool.Count == nil {
			t.Error("AKS default node pool count is nil")
			return
		}
		count := int(*systemPool.Count)
		assert.GreaterOrEqual(t, count, minCount, "AKS default node pool count is below configured minimum")
		assert.LessOrEqual(t, count, maxCount, "AKS default node pool count exceeds configured maximum")
	})
}
