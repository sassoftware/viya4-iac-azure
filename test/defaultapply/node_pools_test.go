// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultapply

import (
	"fmt"
	"os"
	"test/helpers"
	"testing"

	"github.com/Azure/azure-sdk-for-go/services/containerservice/mgmt/2019-11-01/containerservice"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func testApplyNodePools(t *testing.T, plan *terraform.PlanStruct) {
	aksResourceMapName := "module.aks.azurerm_kubernetes_cluster.aks"
	clusterName := helpers.RetrieveFromPlan(plan, aksResourceMapName, "{$.name}")()
	resourceGroupName := helpers.RetrieveFromPlan(plan, "azurerm_resource_group.aks_rg[0]", "{$.name}")()

	cluster, err := azure.GetManagedClusterE(t, resourceGroupName, clusterName, os.Getenv("TF_VAR_subscription_id"))
	if err != nil {
		t.Errorf("Error getting AKS cluster for node pool assertions: %s\n", err)
		return
	}

	if cluster.ManagedClusterProperties == nil || cluster.AgentPoolProfiles == nil {
		t.Error("AKS cluster agent pool profiles are nil")
		return
	}

	poolNames := []string{"stateless", "stateful", "cas", "compute"}
	for _, poolName := range poolNames {
		name := poolName
		t.Run(name, func(t *testing.T) {
			testAdditionalNodePool(t, plan, cluster, name)
		})
	}
}

func testAdditionalNodePool(t *testing.T, plan *terraform.PlanStruct, cluster *containerservice.ManagedCluster, poolName string) {
	var pool *containerservice.ManagedClusterAgentPoolProfile
	for i := range *cluster.AgentPoolProfiles {
		p := (*cluster.AgentPoolProfiles)[i]
		if p.Name != nil && *p.Name == poolName {
			pool = &(*cluster.AgentPoolProfiles)[i]
			break
		}
	}

	if pool == nil {
		t.Errorf("node pool '%s' not found in AKS cluster agent pool profiles", poolName)
		return
	}

	// autoscale_node_pool is always used for the default pools (min != max for all 4)
	poolResourceMapName := fmt.Sprintf("module.node_pools[\"%s\"].azurerm_kubernetes_cluster_node_pool.autoscale_node_pool[0]", poolName)

	tests := map[string]helpers.ApplyTestCase{
		poolName + "PoolProvisioningStateTest": {
			Expected:        "Succeeded",
			ActualRetriever: helpers.RetrieveFromStruct(pool, "ProvisioningState"),
			Message:         fmt.Sprintf("node pool '%s' is not in Succeeded state", poolName),
		},
		poolName + "PoolVMSizeTest": {
			ExpectedRetriever: helpers.RetrieveFromPlan(plan, poolResourceMapName, "{$.vm_size}"),
			ActualRetriever:   helpers.RetrieveFromStruct(pool, "VMSize"),
			Message:           fmt.Sprintf("node pool '%s' VM size does not match plan", poolName),
		},
	}

	helpers.RunApplyTests(t, tests)
}
