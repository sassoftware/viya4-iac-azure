// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test Jump VM disabled: VM, NIC, and public IP must all be absent from the plan.
func TestPlanJumpVmDisabled(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "jump-disabled"
	variables["create_jump_vm"] = false

	tests := map[string]helpers.TestCase{
		"jumpVmAbsent": {
			Expected:          "nil",
			ResourceMapName:   "module.jump[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$}",
			Message:           "Jump VM must not be created when create_jump_vm=false",
		},
		"jumpNicAbsent": {
			Expected:          "nil",
			ResourceMapName:   "module.jump[0].azurerm_network_interface.vm_nic",
			AttributeJsonPath: "{$}",
			Message:           "Jump VM NIC must not be created when create_jump_vm=false",
		},
		"jumpPublicIpAbsent": {
			Expected:          "nil",
			ResourceMapName:   "module.jump[0].azurerm_public_ip.vm_ip[0]",
			AttributeJsonPath: "{$}",
			Message:           "Jump VM public IP must not be created when create_jump_vm=false",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test NFS public IP enabled: the public IP resource must exist with Static allocation.
func TestPlanNfsPublicIpEnabled(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "nfs-public-ip"
	variables["create_nfs_public_ip"] = true

	tests := map[string]helpers.TestCase{
		"nfsPublicIpExists": {
			Expected:          "nil",
			ResourceMapName:   "module.nfs[0].azurerm_public_ip.vm_ip[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "NFS public IP must be created when create_nfs_public_ip=true",
		},
		"nfsPublicIpAllocationStatic": {
			Expected:          "Static",
			ResourceMapName:   "module.nfs[0].azurerm_public_ip.vm_ip[0]",
			AttributeJsonPath: "{$.allocation_method}",
			Message:           "NFS public IP allocation method must be Static by default",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}

// Test Jump VM public IP dynamic allocation when enable_jump_public_static_ip=false.
func TestPlanJumpPublicIpDynamic(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "jump-dynamic-ip"
	variables["enable_jump_public_static_ip"] = false

	tests := map[string]helpers.TestCase{
		"jumpPublicIpAllocationDynamic": {
			Expected:          "Dynamic",
			ResourceMapName:   "module.jump[0].azurerm_public_ip.vm_ip[0]",
			AttributeJsonPath: "{$.allocation_method}",
			Message:           "Jump VM public IP allocation method must be Dynamic when enable_jump_public_static_ip=false",
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
