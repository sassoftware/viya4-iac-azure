// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test storage_type=none: neither the NFS VM nor the NetApp resources should be created.
func TestPlanStorageNone(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "storage-none"
	variables["storage_type"] = "none"

	tests := map[string]helpers.TestCase{
		"nfsVmAbsent": {
			Expected:          "nil",
			ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$}",
			Message:           "NFS VM must not be created when storage_type=none",
		},
		"netappAccountAbsent": {
			Expected:          "nil",
			ResourceMapName:   "module.netapp[0].azurerm_netapp_account.anf",
			AttributeJsonPath: "{$}",
			Message:           "NetApp account must not be created when storage_type=none",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
