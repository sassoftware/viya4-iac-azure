package defaultapply

import (
	"test/helpers"
	"testing"
)

func TestApplyMain(t *testing.T) {
	variables, terraformOptions, _ := helpers.InitAndApply(t)

	defer helpers.DestroyDouble(t, terraformOptions)

	testApplyResourceGroup(t, variables)
	testApplyVM(t, variables)
}
