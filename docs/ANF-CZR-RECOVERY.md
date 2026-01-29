# Azure NetApp Files Cross-Zone Replication (CZR) Recovery Guide

## Overview

When Azure NetApp Files Cross-Zone Replication (CZR) is enabled for a Viya deployment, the IaC automatically provisions a Private DNS Zone that provides a stable hostname for NFS-based workloads. This DNS abstraction eliminates the need for static IP addresses in PersistentVolumes and significantly simplifies the recovery process after ANF failover events.

## Key Concepts

### The DNS Hostname Strategy

- **Static IP Problem**: Without DNS, each PersistentVolume embeds the ANF mount target's IP address. When ANF fails over to a different zone, the IP changes, causing all Viya services to fail.
  
- **DNS Solution**: The IaC creates a Private DNS Zone with an A record (e.g., `nfs.sas-viya.internal`) that points to the active ANF volume. Storage classes reference this hostname instead of a static IP.

### Important DNS Behavior During Failover

The DNS hostname will **always resolve to a valid ANF volume**, but due to ANF CZR semantics:

- **Before failover**: The hostname resolves to the **primary (read/write)** volume
- **During/After failover**: The hostname temporarily resolves to the **replica (read-only)** volume

When the active CZR volume becomes unavailable, Viya services fail because they resolve to the read-only replica. However, recovery is streamlined:

1. **Without DNS**: Each PVC must be deleted and recreated with the new ANF IP (operationally expensive and error-prone)
2. **With DNS**: Simply update the DNS A record to point to the new primary volume IP, then restart Viya services

## Architecture

### Resources Created When CZR is Enabled

```terraform
netapp_enable_cross_zone_replication = true
```

The IaC automatically provisions:

1. **Private DNS Zone**: `<netapp_dns_zone_name>` (default: `sas-viya.internal`)
2. **VNet Link**: Connects the DNS zone to your Azure Virtual Network
3. **DNS A Record**: `<netapp_dns_record_name>.<netapp_dns_zone_name>` (default: `nfs.sas-viya.internal`)
   - Initially points to the primary ANF volume IP
   - TTL: 300 seconds for quick DNS propagation during updates

### DNS-Based NFS Mount

Storage classes and PersistentVolumes use:
```
server: nfs.sas-viya.internal
path: /export
```

Instead of:
```
server: 10.X.Y.Z  # Static IP that changes during failover
path: /export
```

## Configuration Variables

### Required Variables for CZR with DNS

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `netapp_enable_cross_zone_replication` | Enable CZR and automatic DNS zone creation | bool | `false` | Yes |
| `netapp_availability_zone` | Primary volume zone | string | `"1"` | Yes |
| `netapp_replication_zone` | Replica volume zone (must differ from primary) | string | `"2"` | Yes |
| `netapp_network_features` | Must be `"Standard"` for CZR | string | `"Basic"` | Yes (set to `"Standard"`) |
| `netapp_replication_frequency` | Replication interval | string | `"10minutes"` | No |

### Optional DNS Customization

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `netapp_dns_zone_name` | Private DNS Zone name | string | `"sas-viya.internal"` |
| `netapp_dns_record_name` | DNS A record name | string | `"nfs"` |

### Example Configuration

```hcl
# Enable ANF with Cross-Zone Replication and DNS
storage_type = "ha"

# CZR Configuration
netapp_enable_cross_zone_replication = true
netapp_availability_zone             = "1"    # Primary in zone 1
netapp_replication_zone              = "2"    # Replica in zone 2
netapp_network_features              = "Standard"  # Required for CZR
netapp_replication_frequency         = "10minutes"

# Optional DNS Customization
netapp_dns_zone_name   = "viya.internal"      # Custom DNS zone
netapp_dns_record_name = "storage"            # Custom record name
# Result: storage.viya.internal
```

## Recovery Procedure After ANF Failover

### Phase 1: Detection (Immediate)

**Symptoms:**
- All Viya services that mount NFS storage fail
- Pods enter `CrashLoopBackOff` or `Error` states
- NFS mount operations hang or return read-only errors

**Root Cause:**
- The DNS hostname resolves to the replica volume, which is read-only
- The primary volume became unavailable (zone failure, maintenance, etc.)

### Phase 2: DNS Update (Administrator Action)

1. **Identify the New Primary Volume IP**

   Check Terraform outputs:
   ```bash
   terraform output netapp_replica_ip
   # Output: ["10.X.Y.Z"]
   ```

   Or query Azure:
   ```bash
   az netapp volume show \
     --resource-group <rg-name> \
     --account-name <account-name> \
     --pool-name <pool-name>-replica \
     --volume-name <volume-name>-replica \
     --query "mountTargets[0].ipAddress" -o tsv
   ```

2. **Update the DNS A Record**

   Using Azure CLI:
   ```bash
   # Get current DNS configuration
   DNS_ZONE=$(terraform output -raw netapp_dns_hostname | cut -d. -f2-)
   RECORD_NAME=$(terraform output -raw netapp_dns_hostname | cut -d. -f1)
   NEW_PRIMARY_IP=$(terraform output -raw netapp_replica_ip | jq -r '.[0]')
   RG_NAME="<your-resource-group>"

   # Update the A record
   az network private-dns record-set a update \
     --resource-group $RG_NAME \
     --zone-name $DNS_ZONE \
     --name $RECORD_NAME \
     --set aRecords[0].ipv4Address=$NEW_PRIMARY_IP
   ```

   Or via Azure Portal:
   - Navigate to: **Resource Groups** → **Your RG** → **Private DNS zones** → `sas-viya.internal`
   - Select **Record sets** → `nfs`
   - Update **IP address** to the new primary volume IP
   - Click **Save**

3. **Verify DNS Resolution**

   From a VM in the same VNet:
   ```bash
   nslookup nfs.sas-viya.internal
   # Should return the NEW primary IP
   ```

### Phase 3: Viya Service Recovery

1. **Restart All Viya Services**

   ```bash
   # Scale down deployments
   kubectl scale deployment --all --replicas=0 -n <viya-namespace>
   
   # Wait for pods to terminate
   kubectl wait --for=delete pod --all -n <viya-namespace> --timeout=300s
   
   # Scale up deployments
   kubectl scale deployment --all --replicas=1 -n <viya-namespace>
   ```

2. **Verify Pod Recovery**

   ```bash
   # Check pod status
   kubectl get pods -n <viya-namespace> -w
   
   # Verify NFS mounts
   kubectl exec -it <pod-name> -n <viya-namespace> -- df -h | grep sas-viya.internal
   ```

3. **Expected Outcome**
   - All pods successfully reconnect to the NFS endpoint
   - NFS mounts are read/write
   - Viya services return to healthy state

### Phase 4: Post-Recovery Validation

1. **Verify Storage Functionality**
   ```bash
   # Test write access
   kubectl exec -it <pod-name> -n <viya-namespace> -- \
     touch /mnt/storage/test-$(date +%s).txt
   ```

2. **Check ANF Replication Status**
   ```bash
   az netapp volume replication status \
     --resource-group <rg-name> \
     --account-name <account-name> \
     --pool-name <pool-name> \
     --volume-name <volume-name>
   ```

3. **Update Documentation/Runbooks**
   - Document the new primary volume IP
   - Record the failover event timestamp
   - Note any lessons learned

## Outputs Reference

The IaC provides these outputs for CZR management:

| Output | Description | Use Case |
|--------|-------------|----------|
| `netapp_dns_hostname` | Stable DNS hostname (e.g., `nfs.sas-viya.internal`) | Reference in storage class definitions |
| `netapp_primary_ip` | Current primary volume IP | Monitoring, pre-failover reference |
| `netapp_replica_ip` | Current replica volume IP | Post-failover DNS update target |
| `netapp_dns_zone_id` | Private DNS Zone resource ID | Automation scripts for DNS updates |
| `rwx_filestore_endpoint` | Automatically uses DNS when CZR enabled | Used by Viya deployment scripts |

### Viewing Outputs

```bash
# Get the DNS hostname for storage class configuration
terraform output netapp_dns_hostname

# Get replica IP for failover DNS update
terraform output netapp_replica_ip

# Get all CZR-related outputs
terraform output | grep netapp_
```

## Storage Class Configuration

### Automatic DNS Integration

When `netapp_enable_cross_zone_replication = true`, the `rwx_filestore_endpoint` output automatically returns the DNS hostname instead of a static IP.

### Manual Storage Class Example

If configuring storage classes manually:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sas-nfs-storageclass
provisioner: kubernetes.io/nfs
parameters:
  # Use DNS hostname instead of static IP
  server: nfs.sas-viya.internal
  path: /export
mountOptions:
  - vers=4.1
  - hard
  - timeo=600
  - retrans=2
  - rsize=1048576
  - wsize=1048576
```

## Best Practices

### 1. DNS Configuration

- **Use descriptive DNS names**: `nfs.sas-viya.internal` is clearer than `storage.internal`
- **Keep TTL low**: Default 300 seconds balances propagation speed and DNS load
- **Document the DNS zone**: Include zone name in deployment documentation

### 2. Monitoring

- **Set up alerts** for ANF volume health and replication status
- **Monitor DNS resolution** from AKS nodes periodically
- **Track replication lag** to ensure RPO requirements

### 3. Failover Drills

- **Practice DNS updates** in a non-production environment
- **Document timing**: Measure DNS propagation and pod restart duration
- **Automate where possible**: Create scripts for DNS update steps

### 4. Documentation

- **Maintain a runbook** with specific commands for your environment
- **Include contacts**: Who can approve DNS changes, who manages ANF
- **Track changes**: Document all failover events and DNS updates

## Validation

### Pre-Deployment Validation

```bash
# Verify CZR configuration
terraform plan | grep -A 5 "netapp_enable_cross_zone_replication"

# Check DNS resources will be created
terraform plan | grep "azurerm_private_dns"
```

### Post-Deployment Validation

```bash
# Verify DNS zone exists
az network private-dns zone show \
  --resource-group <rg-name> \
  --name sas-viya.internal

# Verify A record
az network private-dns record-set a show \
  --resource-group <rg-name> \
  --zone-name sas-viya.internal \
  --name nfs

# Test DNS resolution from AKS node
kubectl run -it --rm debug-dns --image=busybox --restart=Never -- \
  nslookup nfs.sas-viya.internal
```

## Troubleshooting

### Issue: DNS Not Resolving

**Symptoms:** `nslookup` fails or returns NXDOMAIN

**Checks:**
```bash
# Verify VNet link
az network private-dns link vnet show \
  --resource-group <rg-name> \
  --zone-name sas-viya.internal \
  --name <prefix>-anf-dns-link

# Verify link status is "Completed"
```

**Resolution:** Ensure VNet link is properly configured and linked to the correct VNet

### Issue: DNS Resolves to Wrong IP

**Symptoms:** DNS returns old IP after failover

**Checks:**
```bash
# Check DNS record current value
az network private-dns record-set a show \
  --resource-group <rg-name> \
  --zone-name sas-viya.internal \
  --name nfs \
  --query "aRecords[0].ipv4Address" -o tsv

# Compare with expected IP
terraform output netapp_replica_ip
```

**Resolution:** Update DNS A record to correct IP address

### Issue: Pods Still Failing After DNS Update

**Symptoms:** Pods remain in error state after DNS update

**Checks:**
```bash
# Verify DNS propagation completed
kubectl run -it --rm debug-dns --image=busybox --restart=Never -- \
  nslookup nfs.sas-viya.internal

# Check pod events
kubectl describe pod <pod-name> -n <viya-namespace>
```

**Resolution:** 
1. Wait for DNS TTL to expire (5 minutes by default)
2. Force pod restart if needed
3. Verify new IP is the actual primary (read/write) volume

## Limitations

1. **Service Outage Required**: Viya services must be restarted after DNS update
2. **Manual DNS Update**: DNS record update is not automated (by design, to prevent accidental changes)
3. **Replica is Read-Only**: During the window between failover and DNS update, the replica volume is read-only
4. **DNS Propagation Time**: Pods may take up to TTL (300s) to pick up new IP after DNS update

## References

- [Azure NetApp Files Cross-Zone Replication](https://learn.microsoft.com/en-us/azure/azure-netapp-files/create-cross-zone-replication)
- [Azure Private DNS Zones](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview)
- [Kubernetes NFS Persistent Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#nfs)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-29 | Initial release with automatic DNS zone provisioning for CZR |
