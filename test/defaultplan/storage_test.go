// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
)

func TestPlanStorage(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"userTest": {
			Expected:          "nfsuser",
			ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$.admin_username}",
		},
		"sizeTest": {
			Expected:          "Standard_D4s_v5",
			ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$.size}",
		},
		"vmNotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"vmZoneEmptyStrTest": {
			Expected:          "",
			ResourceMapName:   "module.nfs[0].azurerm_linux_virtual_machine.vm",
			AttributeJsonPath: "{$.vm_zone}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
