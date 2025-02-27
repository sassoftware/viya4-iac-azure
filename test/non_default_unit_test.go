package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test the default variables when using the sample-input-defaults.tfvars file
// with storage_type set to "ha". This should engage the Azure NetApp Files module,
// with the default values as tested herein.
func TestNonDefaultAzureNetApp(t *testing.T) {
	t.Parallel()

	tests := map[string]testCase{
		"accountExists": {
			expected:          `nil`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_account.anf",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"poolExists": {
			expected:          `nil`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"poolServiceLevel": {
			expected:          `Premium`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			attributeJsonPath: "{$.service_level}",
		},
		"poolSize": {
			expected:          `4`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_pool.anf",
			attributeJsonPath: "{$.size_in_tb}",
		},
		"volumeExists": {
			expected:          `nil`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"volumeProtocols": {
			expected:          `["NFSv4.1"]`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$.protocols}",
		},
		"volumeServiceLevel": {
			expected:          `Premium`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$.service_level}",
		},
		"volumePath": {
			expected:          `export`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$.volume_path}",
			assertFunction:    assert.Contains,
		},
		"volumeNetworkFeatures": {
			expected:          `Basic`,
			resourceMapName:   "module.netapp[0].azurerm_netapp_volume.anf",
			attributeJsonPath: "{$.network_features}",
		},
		"subnetExists": {
			expected:          `nil`,
			resourceMapName:   "module.vnet.azurerm_subnet.subnet[\"netapp\"]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
	}

	// Prepare to generate the plan
	varsFilePath := "../examples/sample-input-defaults.tfvars"
	variables := getPlanVars(t, varsFilePath)
	variables["storage_type"] = "ha"

	// Generate the plan
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	// Run the tests
	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Verify ACR disabled
func TestNonDefaultPlanAcrDisabled(t *testing.T) {
	t.Parallel()

	acrDisabledTests := map[string]testCase{
		"acrDisabledTest": {
			expected:          `nil`,
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$}",
			message:           "Azure Container Registry (ACR) present when it should not be",
		},
	}

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = false
	variables["container_registry_admin_enabled"] = true
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range acrDisabledTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Verify ACR standard
func TestNonDefaultPlanACRStandard(t *testing.T) {
	t.Parallel()

	acrStandardTests := map[string]testCase{
		"acrGeoRepsNotExistTest": {
			expected:          "[]",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.georeplications}",
			message:           "Geo-replications found when they should not be present",
		},
		"nameTest": {
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.name}",
			assertFunction:    assert.Contains,
			message:           "ACR name does not contain 'acr'",
		},
		"skuTest": {
			expected:          "Standard",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.sku}",
			message:           "Unexpected ACR SKU value",
		},
		"adminEnabledTest": {
			expected:          "true",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.admin_enabled}",
			message:           "Unexpected ACR admin_enabled value",
		},
	}

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Standard"
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	resource, resourceExists := plan.ResourcePlannedValuesMap["azurerm_container_registry.acr[0]"]
	require.True(t, resourceExists)
	acrName, nameExists := resource.AttributeValues["name"].(string)
	require.True(t, nameExists)
	nameTestCase := acrStandardTests["nameTest"]
	nameTestCase.expected = acrName
	acrStandardTests["nameTest"] = nameTestCase

	for name, tc := range acrStandardTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Verify ACR premium
func TestNonDefaultPlanACRPremium(t *testing.T) {
	t.Parallel()

	acrPremiumTests := map[string]testCase{
		"locationsTest": {
			expected:          "southeastus3 southeastus5",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.georeplications[*].location}",
			message:           "Geo-replications do not match expected values",
		},
		"nameTest": {
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.name}",
			assertFunction:    assert.Contains,
			message:           "ACR name does not contain 'acr'",
		},
		"skuTest": {
			expected:          "Premium",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.sku}",
			message:           "Unexpected ACR SKU value",
		},
		"adminEnabledTest": {
			expected:          "true",
			resourceMapName:   "azurerm_container_registry.acr[0]",
			attributeJsonPath: "{$.admin_enabled}",
			message:           "Unexpected ACR admin_enabled value",
		},
	}

	variables := getDefaultPlanVars(t)
	variables["create_container_registry"] = true
	variables["container_registry_admin_enabled"] = true
	variables["container_registry_sku"] = "Premium"
	variables["container_registry_geo_replica_locs"] = []string{"southeastus5", "southeastus3"}
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	resource, resourceExists := plan.ResourcePlannedValuesMap["azurerm_container_registry.acr[0]"]
	require.True(t, resourceExists)
	acrName, nameExists := resource.AttributeValues["name"].(string)
	require.True(t, nameExists)
	nameTestCase := acrPremiumTests["nameTest"]
	nameTestCase.expected = acrName
	acrPremiumTests["nameTest"] = nameTestCase

	for name, tc := range acrPremiumTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestNonDefaultPostgresServers(t *testing.T) {
	t.Parallel()

	const DefaultPostgresServerName = "default"

	postgresResourceMapName := "module.flex_postgresql[\"" + DefaultPostgresServerName + "\"].azurerm_postgresql_flexible_server.flexpsql"
	tests := map[string]testCase{
		"postgresFlexServerExists": {
			expected:          `nil`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"postgresFlexServerSKUName": {
			expected:          `GP_Standard_D4s_v3`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.sku_name}",
		},
		"postgresFlexServerStorageSize": {
			expected:          `131072`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.storage_mb}",
		},
		"postgresFlexServerBackupRetentionDays": {
			expected:          `7`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.backup_retention_days}",
		},
		"postgresFlexServerGeoRedundantBackup": {
			expected:          `false`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.geo_redundant_backup_enabled}",
		},
		"postgresFlexServerAdminLogin": {
			expected:          `pgadmin`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.administrator_login}",
		},
		"postgresFlexServerAdminPassword": {
			expected:          `my$up3rS3cretPassw0rd`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.administrator_password}",
		},
		"postgresFlexServerVersion": {
			expected:          `15`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.version}",
		},
		"postgresFlexServerSSLEnforcement": {
			expected:          `OFF`,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.postgresql_configurations[*].require_secure_transport}",
			assertFunction:    assert.NotEqual,
		},
		"postgresFlexServerVnetId": {
			expected:          ``,
			resourceMapName:   postgresResourceMapName,
			attributeJsonPath: "{$.virtual_network_id}",
		},
		"postgresFlexServerConfigurationMaxPreparedTransactionsName": {
			expected:          `max_prepared_transactions`,
			resourceMapName:   "module.flex_postgresql[\"" + DefaultPostgresServerName + "\"].azurerm_postgresql_flexible_server_configuration.flexpsql[\"max_prepared_transactions\"]",
			attributeJsonPath: "{$.name}",
		},
		"postgresFlexServerConfigurationMaxPreparedTransactionsValue": {
			expected:          `1024`,
			resourceMapName:   "module.flex_postgresql[\"" + DefaultPostgresServerName + "\"].azurerm_postgresql_flexible_server_configuration.flexpsql[\"max_prepared_transactions\"]",
			attributeJsonPath: "{$.value}",
		},
	}

	// Prepare to generate the plan
	variables := getDefaultPlanVars(t)
	variables["postgres_servers"] = map[string]any{
		DefaultPostgresServerName: map[string]any{},
	}

	// Generate the plan
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	// Run the tests
	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestNonDefaultRbacEnabledGroupIds(t *testing.T) {
	t.Parallel()

	const TENANT_ID = "2492e7f7-df5d-4f17-95dc-63528774e820"

	var ADMIN_IDS = []string{
		"59218b02-7421-4e2d-840a-37ce0d676afa",
		"498afef2-ef42-4099-88f2-4138976df67f",
	}

	tests := map[string]testCase{
		"aadRbacExists": {
			expected:          `nil`,
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.azure_active_directory_role_based_access_control}",
			assertFunction:    assert.NotEqual,
		},
		"aadRbacTenant": {
			expected:          TENANT_ID,
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].tenant_id}",
		},
		"aadRbacAdminIDs": {
			expected:          `["` + ADMIN_IDS[0] + `","` + ADMIN_IDS[1] + `"]`,
			resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
			attributeJsonPath: "{$.azure_active_directory_role_based_access_control[0].admin_group_object_ids}",
		},
	}

	// Initialize the default variables map
	variables := getDefaultPlanVars(t)

	// Set RBAC to true
	variables["rbac_aad_enabled"] = true

	// rbac_aad_tenant_id is required
	variables["rbac_aad_tenant_id"] = TENANT_ID

	// set the rbac_aad_admin_group_object_ids property
	variables["rbac_aad_admin_group_object_ids"] = ADMIN_IDS

	// Generate the plan
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	// Run the tests
	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestNonDefaultRbacEnabledNoTenant(t *testing.T) {
	t.Parallel()

	// Initialize the default variables map
	variables := getDefaultPlanVars(t)

	// Set RBAC to true
	variables["rbac_aad_enabled"] = true

	_, err := initPlanWithVariables(t, variables)
	assert.ErrorContains(t, err, "Missing required argument")
}
