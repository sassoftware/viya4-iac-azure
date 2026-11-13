// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"
)

func TestPlanSubnets(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TupleTestCase{
		"aks": {
			Expected: map[string]helpers.AttrTuple{
				"prefixes":                                 {`["192.168.0.0/23"]`, "{$.address_prefixes}"},
				"serviceEndpoints":                         {`["Microsoft.Sql"]`, "{$.service_endpoints}"},
				"privateEndpointNetworkPolicies":           {`Enabled`, "{$.private_endpoint_network_policies}"},
				"privateLinkServiceNetworkPoliciesEnabled": {`false`, "{$.private_link_service_network_policies_enabled}"},
				"serviceDelegations":                       {``, "{$.service_delegations}"},
			},
		},
		"misc": {
			Expected: map[string]helpers.AttrTuple{
				"prefixes":                                 {`["192.168.2.0/24"]`, "{$.address_prefixes}"},
				"serviceEndpoints":                         {`["Microsoft.Sql"]`, "{$.service_endpoints}"},
				"privateEndpointNetworkPolicies":           {`Enabled`, "{$.private_endpoint_network_policies}"},
				"privateLinkServiceNetworkPoliciesEnabled": {`false`, "{$.private_link_service_network_policies_enabled}"},
				"serviceDelegations":                       {``, "{$.service_delegations}"},
			},
		},
	}

	resourceMapNameFmt := "module.vnet[0].azurerm_subnet.subnet[\"%s\"]"
	helpers.RunTupleTests(t, resourceMapNameFmt, tests, helpers.GetDefaultPlan(t))
}
