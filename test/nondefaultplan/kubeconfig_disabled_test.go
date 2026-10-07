// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test that create_static_kubeconfig=false removes the CRB and ServiceAccount resources.
func TestPlanStaticKubeconfigDisabled(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "kubeconfig-disabled"
	variables["create_static_kubeconfig"] = false

	tests := map[string]helpers.TestCase{
		"kubeconfigCrbAbsent": {
			Expected:          "nil",
			ResourceMapName:   "module.kubeconfig.kubernetes_cluster_role_binding.kubernetes_crb[0]",
			AttributeJsonPath: "{$}",
			Message:           "CRB must not be created when create_static_kubeconfig=false",
		},
		"kubeconfigSaAbsent": {
			Expected:          "nil",
			ResourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			AttributeJsonPath: "{$}",
			Message:           "ServiceAccount must not be created when create_static_kubeconfig=false",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
