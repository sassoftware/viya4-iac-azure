// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"
)

// TestAdminAccess verifies that NSG rules for admin access are correctly applied in the Terraform plan.
func TestPlanAdminAccess(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"defaultCidrTest": {
			Expected:          "{[123.45.67.89/16]}",
			ResourceMapName:   "default_public_access_cidrs",
			Retriever:         helpers.RetrieveFromRawPlanResource,
			AttributeJsonPath: "{$}",
			Message:           "Mismatch in default_public_access_cidrs",
		},
		"clusterCidrTest": {
			Expected:          "{<nil>}",
			ResourceMapName:   "cluster_endpoint_public_access_cidrs",
			Retriever:         helpers.RetrieveFromRawPlanResource,
			AttributeJsonPath: "{$}",
			Message:           "Mismatch in cluster_endpoint_public_access_cidrs",
		},
		"vmCidrTest": {
			Expected:          "{<nil>}",
			ResourceMapName:   "vm_public_access_cidrs",
			Retriever:         helpers.RetrieveFromRawPlanResource,
			AttributeJsonPath: "{$}",
			Message:           "Mismatch in vm_public_access_cidrs",
		},
		"postgresCidrTest": {
			Expected:          "{<nil>}",
			ResourceMapName:   "vm_public_access_cidrs",
			Retriever:         helpers.RetrieveFromRawPlanResource,
			AttributeJsonPath: "{$}",
			Message:           "Mismatch in postgres_public_access_cidrs",
		},
		"acrCidrTest": {
			Expected:          "{<nil>}",
			ResourceMapName:   "acr_public_access_cidrs",
			Retriever:         helpers.RetrieveFromRawPlanResource,
			AttributeJsonPath: "{$}",
			Message:           "Mismatch in acr_public_access_cidrs",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
