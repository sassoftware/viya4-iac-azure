package defaultapply

import (
	"test/helpers"
	"testing"
)

func TestApplyMain(t *testing.T) {
	terraformOptions, plan := helpers.InitAndApply(t)

	defer helpers.DestroyDouble(t, terraformOptions)

	// Drop in new test cases here
	testApplyResourceGroup(t, plan)
	testApplyVirtualMachine(t, plan)
}
