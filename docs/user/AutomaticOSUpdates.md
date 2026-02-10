# Automatic OS Updates for Jump and NFS VMs

## Overview

Azure Update Manager manages OS patches for Jump and NFS virtual machines.

## Configuration Variables

### vm_patch_mode
- **Default:** `"ImageDefault"` (manual patching)
- **Values:** `"ImageDefault"` | `"AutomaticByPlatform"`

### vm_patch_assessment_mode
- **Default:** `"AutomaticByPlatform"` (automatic scan)
- **Values:** `"ImageDefault"` | `"AutomaticByPlatform"`

## Default Behavior

No `.tfvars` changes needed. Defaults provide:
- Automatic patch detection
- Manual installation control
- Safe for production NFS

## Deployment

### Production (Use Defaults)
```hcl
# No patch variables needed in .tfvars
```

### Dev/Test (Enable Auto-Patching)
```hcl
vm_patch_mode            = "AutomaticByPlatform"
vm_patch_assessment_mode = "AutomaticByPlatform"
```

## Requirements for Automatic Patching

To enable automatic OS upgrades, ensure:

1. **VM Agent Running**: Azure VM agent must be installed and running
2. **Patch Mode**: Set `vm_patch_mode = "AutomaticByPlatform"`
3. **Network Connectivity**: VM must reach Azure Update Manager endpoints

## Monitoring

**Azure Portal:**
Virtual Machines → Select VM → Operations → Updates

**Check patch status:**
```powershell
az vm get-instance-view --resource-group <rg-name> --name <vm-name> --query "patchStatus"
```

**Trigger assessment:**
```powershell
az vm assess-patches --resource-group <rg-name> --name <vm-name>
```

**Install patches:**
```powershell
az vm install-patches --resource-group <rg-name> --name <vm-name> --maximum-duration PT2H --reboot-setting IfRequired
```

## Best Practices

- Keep `vm_patch_mode = "ImageDefault"` for NFS VMs (prevents storage disruption)
- Use automatic patching only in dev/test environments
- Plan maintenance windows for production
- Test patches before production deployment

## ⚠️ Important: Backup Before Patching

**Always create backups before installing OS updates:**

1. **Take VM snapshots** or use Azure Backup before patching
2. **For NFS VMs:** Backup data stored on NFS volumes
3. **Test restore procedures** to ensure backups are valid
4. **Document rollback steps** in case of patch failures

**Azure Backup commands:**
```powershell
# Enable backup for VM
az backup protection enable-for-vm --resource-group <rg-name> --vault-name <backup-vault> --vm <vm-name> --policy-name DefaultPolicy

# Trigger on-demand backup
az backup protection backup-now --resource-group <rg-name> --vault-name <backup-vault> --container-name <vm-name> --item-name <vm-name>
```

Microsoft and SAS are not responsible for data loss or system failures resulting from OS updates. Backups are your responsibility.

## Troubleshooting

**No patches showing:**
```powershell
az vm assess-patches --resource-group <rg-name> --name <vm-name>
```

**NFS unavailable after patching:**
```bash
sudo systemctl restart nfs-kernel-server
```

## Related Documentation

- [Azure Update Manager](https://docs.microsoft.com/en-us/azure/update-manager/)
- [CONFIG-VARS.md](../CONFIG-VARS.md)
