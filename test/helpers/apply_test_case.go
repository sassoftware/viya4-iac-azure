package helpers

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

// ApplyTestCase struct defines the attributes for a test case
type ApplyTestCase struct {
	Expected          interface{}
	ExpectedRetriever func() string
	Actual            interface{}
	ActualRetriever   func() string
	AssertFunction    assert.ComparisonAssertionFunc
	Message           string
}

// RunApplyTest runs a test case
func RunApplyTest(t *testing.T, tc ApplyTestCase) {
	expected := tc.Expected
	if tc.ExpectedRetriever != nil {
		expected = tc.ExpectedRetriever()
	}
	actual := tc.Actual
	if tc.ActualRetriever != nil {
		actual = tc.ActualRetriever()
	}
	assertFn := tc.AssertFunction
	if assertFn == nil {
		assertFn = assert.Equal
	}
	validateFn := AssertComparison(assertFn, expected)
	validateFn(t, actual, tc.Message)
}

// RunApplyTests ranges over a set of test cases and runs them
func RunApplyTests(t *testing.T, tests map[string]ApplyTestCase) {
	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			RunApplyTest(t, tc)
		})
	}
}
