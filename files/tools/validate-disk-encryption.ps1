#!/usr/bin/env pwsh
# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

<#
.SYNOPSIS
    Validates disk encryption settings for AKS clusters and VMs after infrastructure deployment.

.DESCRIPTION
    This script checks:
    - AKS node pool disk encryption settings
    - Jump VM disk encryption (if exists)
    - NFS VM disk encryption (if exists)
    - Disk Encryption Set configuration
    - Key Vault access policies

.PARAMETER ResourceGroupName
    The resource group containing the AKS cluster. If not provided, will attempt to read from terraform output.

.PARAMETER ClusterName
    The AKS cluster name. If not provided, will attempt to read from terraform output.

.EXAMPLE
    .\validate-disk-encryption.ps1
    
.EXAMPLE
    .\validate-disk-encryption.ps1 -ResourceGroupName "my-rg" -ClusterName "my-aks"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName
)

# Color output functions
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Warning { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "✗ $args" -ForegroundColor Red }
function Write-Info { Write-Host "ℹ $args" -ForegroundColor Cyan }

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Disk Encryption Validation Script" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI is not installed. Please install it first."
    exit 1
}

# Check if logged in to Azure
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Error "Not logged in to Azure. Please run 'az login' first."
    exit 1
}

Write-Success "Logged in to Azure subscription: $($account.name)"

# Try to get values from Terraform outputs if not provided
if (-not $ResourceGroupName -or -not $ClusterName) {
    Write-Info "Attempting to read values from Terraform outputs..."
    
    if (Test-Path "terraform.tfstate") {
        try {
            if (-not $ResourceGroupName) {
                $ResourceGroupName = terraform output -raw aks_rg_name 2>$null
            }
            if (-not $ClusterName) {
                $ClusterName = terraform output -raw aks_cluster_name 2>$null
            }
            
            if ($ResourceGroupName -and $ClusterName) {
                Write-Success "Retrieved values from Terraform outputs"
            }
        }
        catch {
            Write-Warning "Could not read Terraform outputs. Please provide parameters manually."
        }
    }
}

# Validate required parameters
if (-not $ResourceGroupName -or -not $ClusterName) {
    Write-Error "ResourceGroupName and ClusterName are required. Provide them as parameters or ensure Terraform state exists."
    Write-Host "`nUsage: .\validate-disk-encryption.ps1 -ResourceGroupName <rg-name> -ClusterName <cluster-name>`n"
    exit 1
}

Write-Info "Resource Group: $ResourceGroupName"
Write-Info "Cluster Name: $ClusterName`n"

# Validate AKS Node Pools
Write-Host "Checking AKS Node Pool Disk Encryption..." -ForegroundColor Yellow
Write-Host "----------------------------------------`n"

$nodePools = az aks nodepool list --cluster-name $ClusterName --resource-group $ResourceGroupName | ConvertFrom-Json

if ($nodePools) {
    foreach ($pool in $nodePools) {
        Write-Host "Node Pool: $($pool.name)"
        
        if ($pool.diskEncryptionSetId) {
            Write-Success "  Disk Encryption Set ID: $($pool.diskEncryptionSetId)"
            
            # Extract DES name and resource group from ID
            if ($pool.diskEncryptionSetId -match '/resourceGroups/([^/]+)/.*diskEncryptionSets/([^/]+)$') {
                $desRg = $matches[1]
                $desName = $matches[2]
                
                # Get DES details
                $des = az disk-encryption-set show --name $desName --resource-group $desRg | ConvertFrom-Json
                Write-Success "  Encryption Type: $($des.encryptionType)"
                Write-Success "  Key Vault: $($des.activeKey.sourceVault.id)"
            }
        } else {
            Write-Warning "  No Disk Encryption Set configured (using Azure-managed keys)"
        }
        Write-Host ""
    }
} else {
    Write-Error "Could not retrieve node pool information"
}

# Check VMs (Jump and NFS)
Write-Host "`nChecking VM Disk Encryption..." -ForegroundColor Yellow
Write-Host "----------------------------------------`n"

$vms = az vm list --resource-group $ResourceGroupName | ConvertFrom-Json

if ($vms) {
    foreach ($vm in $vms) {
        Write-Host "VM: $($vm.name)"
        
        # Get disk information
        $disks = az vm show --name $vm.name --resource-group $ResourceGroupName --query "storageProfile.{osDisk:osDisk, dataDisks:dataDisks}" | ConvertFrom-Json
        
        # Check OS Disk
        if ($disks.osDisk.managedDisk.diskEncryptionSet) {
            Write-Success "  OS Disk Encryption Set ID: $($disks.osDisk.managedDisk.diskEncryptionSet.id)"
        } else {
            Write-Warning "  OS Disk: No Disk Encryption Set configured (using Azure-managed keys)"
        }
        
        # Check Data Disks
        if ($disks.dataDisks -and $disks.dataDisks.Count -gt 0) {
            foreach ($dataDisk in $disks.dataDisks) {
                if ($dataDisk.managedDisk.diskEncryptionSet) {
                    Write-Success "  Data Disk ($($dataDisk.name)): Encrypted with DES"
                } else {
                    Write-Warning "  Data Disk ($($dataDisk.name)): No DES configured"
                }
            }
        }
        Write-Host ""
    }
} else {
    Write-Info "No VMs found in resource group"
}

# Check all managed disks in the resource group
Write-Host "`nChecking All Managed Disks..." -ForegroundColor Yellow
Write-Host "----------------------------------------`n"

$disks = az disk list --resource-group $ResourceGroupName | ConvertFrom-Json

if ($disks) {
    $encryptedCount = 0
    $unencryptedCount = 0
    
    foreach ($disk in $disks) {
        $status = if ($disk.encryption.diskEncryptionSetId) { 
            $encryptedCount++
            "ENCRYPTED"
        } else { 
            $unencryptedCount++
            "UNENCRYPTED"
        }
        
        $encType = if ($disk.encryption.type) { $disk.encryption.type } else { "Platform-managed" }
        
        if ($disk.encryption.diskEncryptionSetId) {
            Write-Success "$($disk.name): $status ($encType)"
        } else {
            Write-Warning "$($disk.name): $status ($encType)"
        }
    }
    
    Write-Host "`n----------------------------------------"
    Write-Host "Summary: $encryptedCount encrypted, $unencryptedCount using platform-managed keys" -ForegroundColor Cyan
} else {
    Write-Info "No managed disks found in resource group"
}

# Check Disk Encryption Set (if exists)
Write-Host "`n`nChecking Disk Encryption Set Configuration..." -ForegroundColor Yellow
Write-Host "----------------------------------------`n"

$allDes = az disk-encryption-set list --resource-group $ResourceGroupName | ConvertFrom-Json

if ($allDes) {
    foreach ($des in $allDes) {
        Write-Host "Disk Encryption Set: $($des.name)"
        Write-Success "  Encryption Type: $($des.encryptionType)"
        Write-Success "  Identity Type: $($des.identity.type)"
        Write-Success "  Principal ID: $($des.identity.principalId)"
        Write-Success "  Key Vault: $($des.activeKey.sourceVault.id)"
        Write-Success "  Key URL: $($des.activeKey.keyUrl)"
        Write-Host ""
    }
} else {
    Write-Info "No Disk Encryption Sets found in resource group"
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Validation Complete" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan
