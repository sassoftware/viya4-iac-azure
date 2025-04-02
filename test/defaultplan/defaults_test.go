// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"nodeVmAdminTest": {
			Expected:          "azureuser",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.linux_profile[0].admin_username}",
		},
		"clusterEgressTypeTest": {
			Expected:          "loadBalancer",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.network_profile[0].outbound_type}",
		},
		"networkPluginTest": {
			Expected:          "kubenet",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.network_profile[0].network_plugin}",
		},
		"k8sVersionTest": {
			Expected:          "1.30",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.kubernetes_version}",
		},
		"skuTierTest": {
			Expected:          "Free",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.sku_tier}",
		},
		"supportPlanTest": {
			Expected:          "KubernetesOfficial",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.support_plan}",
		},
		"userIdentityTest": {
			Expected:          "",
			ResourceMapName:   "azurerm_user_assigned_identity.uai[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"rbacTest": {
			Expected:          `[]`,
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_active_directory_role_based_access_control}",
		},
		"jumpVmSSHKey": {
			Expected:          "<nil>",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.linux_profile[0].ssh_key[0].key_data}",
			AssertFunction:    assert.NotEqual,
			Message:           "The Jump VM machine type should be Standard_B2s",
		},
		"runCommandDefaultTest": {
			Expected:          "false",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.run_command_enabled}",
			Message:           "The AKS cluster Run Command feature should be disabled by default",
		},
		"azurePolicyDefaultTest": {
			Expected:          "false",
			ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			AttributeJsonPath: "{$.azure_policy_enabled}",
			Message:           "Unexpected azure_policy_enabled value; disabled by default",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}

// Test the general variables when using the sample-input-defaults.tfvars file.
func TestPlanGeneral(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"kubeconfigCrbResourceNotNil": {
			Expected:          "<nil>",
			ResourceMapName:   "module.kubeconfig.kubernetes_cluster_role_binding.kubernetes_crb[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "The kubeconfig CRB resource should exist",
		},
		"kubeconfigSAResourceNotNil": {
			Expected:          "<nil>",
			ResourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "The kubeconfig Service Account resource should exist",
		},
		"jumpVmNotNil": {
			Expected:          "<nil>",
			ResourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "The Jump VM resource should exist",
		},
		"jumpVmPublicIpNotNil": {
			Expected:          "<nil>",
			ResourceMapName:   "module.jump[0].azurerm_public_ip.vm_ip[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "The Jump VM Public IP resource should exist",
		},
		"jumpVmEnablePublicStaticIp": {
			Expected:          "Static",
			ResourceMapName:   "module.jump[0].azurerm_public_ip.vm_ip[0]",
			AttributeJsonPath: "{$.allocation_method}",
			AssertFunction:    assert.Equal,
			Message:           "The Jump VM Public IP resource should have a Static allocation method",
		},
		"jumpVmAdmin": {
			Expected:          "jumpuser",
			ResourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$.admin_username}",
			AssertFunction:    assert.Equal,
			Message:           "The Jump VM admin username should be jumpuser",
		},
		"jumpVmMachineType": {
			Expected:          "Standard_B2s",
			ResourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$.size}",
			AssertFunction:    assert.Equal,
			Message:           "The Jump VM machine type should be Standard_B2s",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}

func TestPlanAcrDisabled(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"acrDisabledTest": {
			Expected:          `nil`,
			ResourceMapName:   "azurerm_container_registry.acr[0]",
			AttributeJsonPath: "{$}",
			Message:           "Azure Container Registry (ACR) present when it should not be",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
