# Quick Start: Creating Ubuntu Pro FIPS 22.04 Custom Image


✅ **Tested Method**: Uses the official Ubuntu Pro FIPS 22.04 marketplace image as the base  
✅ **Standard Azure Process**: Follows Microsoft's documented custom image creation process  
✅ **AKS Compatible**: The resulting image meets all AKS node requirements  
✅ **FIPS Verified**: FIPS modules are pre-installed and enabled in the base image  

## Do You Really Need This?

### When to Use Custom Ubuntu 22.04 Image

**✅ Use this approach if:**
- Compliance requires Ubuntu 22.04 specifically on AKS worker nodes
- Company policy mandates Ubuntu 22.04 across all infrastructure
- You need Ubuntu 22.04 kernel features (eBPF improvements, newer hardware support)
- Specific applications require Ubuntu 22.04
- You want to pre-install custom software on all nodes
- Long-term support alignment with other systems

**❌ Don't use this if:**
- Ubuntu 20.04 FIPS is acceptable (it's supported until 2030)
- You want zero maintenance overhead
- Limited time/resources for image management
- No specific Ubuntu 22.04 requirement

### Simple Alternative (Recommended for Most)

If you don't specifically need Ubuntu 22.04 on AKS worker nodes, just use:

```hcl
fips_enabled = true
# AKS nodes: Ubuntu 20.04 FIPS (Azure-managed, automatic updates)
# Jump/NFS VMs: Ubuntu 22.04 FIPS (already automatic)
```

**To use Ubuntu 22.04 on AKS nodes:**

```hcl
fips_enabled              = true
use_custom_image_for_fips = true
custom_node_source_image_id = "<image-id-from-script>"
# AKS nodes: Ubuntu 22.04 FIPS (Custom image, manual updates required)
# Jump/NFS VMs: Ubuntu 22.04 FIPS (already automatic)
```



## Pros and Cons

### ✅ Pros of Custom Ubuntu 22.04 Image

| Benefit | Description |
|---------|-------------|
| **Latest Ubuntu LTS** | Access to Ubuntu 22.04 features and kernel improvements |
| **Full Customization** | Pre-install any software, tools, or configurations |
| **Consistency** | Same OS version across all infrastructure |
| **Compliance** | Meet specific regulatory requirements for Ubuntu 22.04 |
| **Control** | You decide when and how to update the OS |
| **Pre-configured Nodes** | Nodes boot with Docker, kubectl, Helm already installed |

### ❌ Cons of Custom Ubuntu 22.04 Image

| Drawback | Description |
|----------|-------------|
| **Manual Maintenance** | YOU must rebuild images for security patches |
| **Update Responsibility** | No automatic OS updates from Azure |
| **Setup Time** | Initial setup takes 30-40 minutes |
| **Storage Costs** | ~$1-2/month for image storage |
| **Operational Overhead** | Need to monitor CVEs and rebuild images |
| **Complexity** | More moving parts to manage |
| **Image Lifecycle** | Must track and delete old image versions |
| **Region Dependency** | Image must be in same region as AKS cluster |

### ⚖️ Comparison Table

| Aspect | Default (Ubuntu 20.04) | Custom Image (Ubuntu 22.04) |
|--------|------------------------|------------------------------|
| **Setup Time** | 0 minutes | 30-40 minutes (one-time) |
| **Configuration** | `fips_enabled = true` | `fips_enabled = true`<br>`use_custom_image_for_fips = true`<br>`custom_node_source_image_id = "<id>"` |
| **Security Updates** | Automatic (Azure manages) | **Manual (you must rebuild)** |
| **Patching** | Automatic | **Your responsibility** |
| **Cost** | $0 extra | ~$1-2/month storage |
| **Maintenance** | None | **Regular image rebuilds required** |
| **Flexibility** | Limited | Full customization |
| **Risk** | Very low | Medium (update lag risk) |
| **Support** | Azure supported | Self-managed |

## Important Limitations

### 🚨 Critical Limitations

1. **Manual Security Patching Required**
   - Azure does NOT automatically update custom images
   - YOU must monitor security bulletins (CVEs)
   - YOU must rebuild and redeploy images for patches
   - Risk: Delayed patching can expose vulnerabilities

2. **No Automatic OS Updates**
   - AKS node image upgrade channels are disabled when using custom images
   - `node_os_upgrade_channel` setting is ignored
   - You lose Azure's automated patching pipeline

3. **Region and Subscription Constraints**
   - Image must be in the SAME subscription as AKS cluster
   - Image must be replicated to the SAME region as AKS cluster
   - Cross-subscription usage requires complex RBAC setup

4. **Image Lifecycle Management**
   - You must track image versions
   - Old versions accumulate storage costs
   - No automatic cleanup of unused versions
   - Must manually delete old images

5. **Node Pool Updates**
   - Changing image requires node pool recreation or rotation
   - Cannot update running nodes without replacement
   - Potential downtime during updates

6. **Storage Overhead**
   - Each image version takes ~15-30 GB storage
   - Multiple versions multiply costs
   - Gallery replication increases costs

7. **Build Time Dependency**
   - Emergency patches require 30-40 minute rebuild
   - Cannot instantly deploy critical security fixes
   - Build VM quota/availability can delay updates

### 📋 Ongoing Maintenance Requirements

When using custom images, you MUST:

- [ ] **Monthly**: Check for Ubuntu security updates
- [ ] **Weekly**: Monitor CVE databases for critical patches
- [ ] **As Needed**: Rebuild image when patches available
- [ ] **Quarterly**: Review and delete old image versions
- [ ] **After Rebuild**: Update Terraform and redeploy nodes
- [ ] **Continuously**: Track image version inventory

### 💡 Recommendation

**For most deployments, use the default approach:**
```hcl
fips_enabled = true
```

**Only use custom images if you:**
- Have dedicated resources for image maintenance
- Have a specific, documented requirement for Ubuntu 22.04
- Can commit to regular image rebuilds and testing
- Understand the security implications of manual patching

## Prerequisites

Before running the script, ensure you have:

- [ ] Azure CLI installed ([Install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- [ ] Logged into Azure (`az login`)
- [ ] Contributor access to the subscription
- [ ] SSH key pair generated (`~/.ssh/id_rsa.pub` must exist)
- [ ] 30-45 minutes of time (mostly automated waiting)

## Step-by-Step Process

### Using Bash Script (Linux/Mac/WSL/Git Bash)

```bash
# 1. Navigate to the scripts directory
cd scripts/

# 2. Make script executable
chmod +x create-fips-2204-image.sh

# 3. Run the script
./create-fips-2204-image.sh

# Or with environment variables:
SUBSCRIPTION_ID="your-sub-id" \
RESOURCE_GROUP="my-custom-rg" \
LOCATION="eastus" \
./create-fips-2204-image.sh
```

## What the Script Does

The script automates these steps:

1. **Accepts Marketplace Terms** - For Ubuntu Pro FIPS 22.04 image
2. **Creates Resource Group** - For image storage
3. **Creates Azure Compute Gallery** - Shared image gallery
4. **Creates Image Definition** - Defines the image template
5. **Creates Build VM** - Temporary VM from Ubuntu Pro FIPS 22.04
6. **Customizes VM** - Installs Docker, kubectl, Azure CLI, Helm
7. **Verifies FIPS** - Confirms FIPS mode is enabled
8. **Captures Image** - Generalizes and captures VM to gallery
9. **Outputs Image ID** - Provides the ID for your Terraform config


## After Image Creation

### 1. Get the Image ID

The script outputs something like:

```
Image ID:
/subscriptions/xxx-xxx-xxx/resourceGroups/viya4-image-builder/providers/Microsoft.Compute/galleries/viya4ImageGallery/images/ubuntu-pro-fips-2204/versions/1.0.0
```

### 2. Update Your Terraform Configuration

In your `.tfvars` file:

```hcl
# Enable FIPS and use custom Ubuntu 22.04 image
fips_enabled                = true
use_custom_image_for_fips   = true
custom_node_source_image_id = "/subscriptions/xxx-xxx-xxx/resourceGroups/viya4-image-builder/providers/Microsoft.Compute/galleries/viya4ImageGallery/images/ubuntu-pro-fips-2204/versions/1.0.0"
```

### 3. Deploy Your AKS Cluster

```bash
terraform init
terraform plan
terraform apply
```

## Verification

After AKS deployment, verify Ubuntu 22.04 is running:

```bash
# Get kubeconfig
export KUBECONFIG=./generated/kubeconfig

# Check node OS version
kubectl get nodes -o wide

# SSH to a node and check
kubectl debug node/<node-name> -it --image=ubuntu

# Inside debug pod:
cat /host/etc/os-release
# Should show: VERSION="22.04.x LTS (Jammy Jellyfish)"

cat /host/proc/sys/crypto/fips_enabled
# Should show: 1
```

## End-to-End Testing Guide

For a complete testing workflow with detailed steps and validation checklist, follow these phases:

### Phase 1: Prerequisites Validation

Ensure you have:
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Azure subscription with Owner or Contributor permissions
- [ ] Terraform v1.0 or later installed
- [ ] kubectl installed for cluster verification
- [ ] SSH key pair at `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`
- [ ] Marketplace terms accepted:
  ```bash
  az vm image terms accept \
    --urn Canonical:0001-com-ubuntu-pro-jammy-fips:pro-fips-22_04:latest \
    --subscription <your-subscription-id>
  ```

### Phase 2: Create Custom Image (30-40 minutes)

```bash
# Configure environment
export SUBSCRIPTION_ID="<your-subscription-id>"
export RESOURCE_GROUP="viya4-image-builder"
export GALLERY_NAME="viya4ImageGallery"
export LOCATION="eastus"
export IMAGE_VERSION="1.0.0"

# Run image creation script
cd scripts
chmod +x create-fips-2204-image.sh
./create-fips-2204-image.sh
```

**Expected output:** Image ID in format:
```
/subscriptions/.../resourceGroups/viya4-image-builder/providers/Microsoft.Compute/galleries/viya4ImageGallery/images/ubuntu-pro-fips-2204/versions/1.0.0
```

Verify image:
```bash
az sig image-version show \
  --resource-group viya4-image-builder \
  --gallery-name viya4ImageGallery \
  --gallery-image-definition ubuntu-pro-fips-2204 \
  --gallery-image-version 1.0.0 \
  --query provisioningState -o tsv
# Should output: Succeeded
```

### Phase 3: Configure Terraform

Create `terraform.tfvars` (or copy from `examples/sample-input-fips-ubuntu-2204.tfvars`):

```hcl
# Authentication
subscription_id = "<your-subscription-id>"
tenant_id       = "<your-tenant-id>"

# General
prefix   = "fips2204test"
location = "eastus"

# AKS Cluster
kubernetes_version = "1.33"

# FIPS with Ubuntu Pro 22.04
fips_enabled                = true
use_custom_image_for_fips   = true
custom_node_source_image_id = "/subscriptions/<subscription-id>/resourceGroups/viya4-image-builder/providers/Microsoft.Compute/galleries/viya4ImageGallery/images/ubuntu-pro-fips-2204/versions/1.0.0"

# Node Pools
default_nodepool_min_nodes = 1
default_nodepool_max_nodes = 3
default_nodepool_vm_type   = "Standard_E8s_v5"

# Optional: Additional node pools
node_pools = {
  cas = {
    machine_type              = "Standard_E8s_v5"
    os_disk_size              = 200
    min_nodes                 = 1
    max_nodes                 = 2
    max_pods                  = 110
    node_taints               = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels               = { "workload.sas.com/class" = "cas" }
    linux_os_config           = null
    community_priority        = "Regular"
    community_eviction_policy = null
    community_spot_max_price  = null
  }
}

# Storage
storage_type = "standard"

# Optional: Disable Jump VM for faster testing
create_jump_vm = false

# Tags
tags = {
  environment = "test"
  purpose     = "fips-ubuntu-2204-validation"
}
```

Validate configuration:
```bash
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars
```

### Phase 4: Deploy AKS Cluster (10-15 minutes)

```bash
terraform apply -var-file=terraform.tfvars
# Type 'yes' when prompted
```

Configure kubectl:
```bash
export KUBECONFIG=$(terraform output -raw kube_config_path)
# Or: az aks get-credentials --resource-group <rg-name> --name <cluster-name>
```

Verify cluster:
```bash
kubectl get nodes
# All nodes should show "Ready" status
```

### Phase 5: Detailed Verification

**Check OS version on all nodes:**
```bash
kubectl get nodes -o wide
# Look for "Ubuntu 22.04" in OS-IMAGE column
```

**Verify FIPS on a specific node:**
```bash
# Get first node name
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# Create debug pod
kubectl debug node/$NODE_NAME -it --image=busybox -- sh

# Inside debug pod:
cat /host/etc/os-release | grep VERSION
# Expected: VERSION="22.04.x LTS (Jammy Jellyfish)"

cat /host/proc/sys/crypto/fips_enabled
# Expected: 1

cat /host/proc/cmdline | grep fips
# Expected: Should contain "fips=1"

# Exit debug pod
exit
```

**Verify all node pools:**
```bash
# Check each node pool uses Ubuntu 22.04
for node in $(kubectl get nodes -o name); do
  echo "Checking $node..."
  kubectl debug $node -it --image=busybox -- cat /host/etc/os-release | grep VERSION_ID
done
# All should show: VERSION_ID="22.04"
```

### Phase 6: Optional Workload Testing

Deploy test workload:
```bash
kubectl create deployment nginx --image=nginx:latest --replicas=2
kubectl expose deployment nginx --port=80 --type=ClusterIP
kubectl get pods -o wide
# Verify pods are scheduled on FIPS nodes
```

Cleanup test:
```bash
kubectl delete deployment nginx
kubectl delete service nginx
```

### Phase 7: Cleanup (Optional)

**Option A - Destroy everything:**
```bash
terraform destroy -var-file=terraform.tfvars
```

**Option B - Keep cluster, delete custom image:**
```bash
# Delete image resources
az group delete --name viya4-image-builder --yes --no-wait
```

## Testing Validation Checklist

Use this checklist to confirm end-to-end success:

### ✅ Image Creation Phase
- [ ] Script completed without errors
- [ ] Image ID was output at the end
- [ ] Image exists in Azure Compute Gallery with "Succeeded" status
- [ ] Image is in the same region as planned AKS deployment

### ✅ Terraform Configuration Phase
- [ ] `terraform validate` passed
- [ ] `terraform plan` showed custom image reference in node pool config
- [ ] No errors about invalid image ID format

### ✅ Cluster Deployment Phase
- [ ] `terraform apply` completed successfully
- [ ] Kubeconfig was generated
- [ ] `kubectl get nodes` shows all nodes Ready

### ✅ Verification Phase
- [ ] Nodes show "Ubuntu 22.04" in `kubectl get nodes -o wide`
- [ ] `/proc/sys/crypto/fips_enabled` returns `1` on all nodes
- [ ] `/proc/cmdline` contains `fips=1` on all nodes
- [ ] All node pools (default + additional) use Ubuntu 22.04
- [ ] `/etc/os-release` shows VERSION_ID="22.04"

### ✅ Optional Testing
- [ ] Test workloads deploy successfully
- [ ] Pods run correctly on FIPS-enabled nodes
- [ ] No kernel panics or boot issues

## Expected Timeline

| Phase | Duration | Notes |
|-------|----------|-------|
| Prerequisites setup | 5-10 min | One-time |
| Image creation | 30-40 min | VM build + customization + capture |
| Terraform config | 5 min | Edit tfvars file |
| Terraform apply | 10-15 min | AKS cluster creation |
| Verification | 5-10 min | Node checks |
| **Total** | **55-80 min** | First-time complete flow |

## Common Testing Issues

### Issue: Nodes still show Ubuntu 20.04

**Causes:**
- `use_custom_image_for_fips` not set to `true` in tfvars
- `custom_node_source_image_id` not set correctly in tfvars
- Image ID format is incorrect
- AKS didn't pick up the custom image

**Solution:**
```bash
# Verify your tfvars has all three settings:
# fips_enabled = true
# use_custom_image_for_fips = true
# custom_node_source_image_id = "<image-id>"

# Check Terraform state
terraform show | grep source_image_id

# Verify image ID format matches:
# /subscriptions/.../galleries/.../images/.../versions/...

# If incorrect, fix tfvars and reapply
terraform apply -var-file=terraform.tfvars
```

### Issue: FIPS disabled on nodes

**Cause:** Custom image wasn't built with FIPS enabled

**Solution:** Re-run image creation script (it enables FIPS automatically)

### Issue: Terraform shows "InvalidParameter" for image ID

**Causes:**
- Image not in same subscription as AKS cluster
- Image not in same region as AKS cluster
- Image ID malformed

**Solution:**
```bash
# Check image exists and location matches
az sig image-version show \
  --resource-group viya4-image-builder \
  --gallery-name viya4ImageGallery \
  --gallery-image-definition ubuntu-pro-fips-2204 \
  --gallery-image-version 1.0.0 \
  --query "[location, provisioningState]" -o tsv

# Ensure location matches your terraform location variable
```

### Issue: kubectl debug fails

**Alternative debug methods:**
```bash
# Try different debug image
kubectl debug node/$NODE_NAME -it --image=ubuntu:22.04 -- bash

# Or use Azure CLI to connect to VM scale set instance
az vmss list-instances \
  --resource-group MC_<resource-group>_<cluster-name>_<location> \
  --name <vmss-name> -o table
```

## Troubleshooting

### Issue: "Marketplace terms not accepted"

```bash
az vm image terms accept \
  --urn Canonical:0001-com-ubuntu-pro-jammy-fips:pro-fips-22_04:latest \
  --subscription <your-sub-id>
```

### Issue: "SSH key not found"

```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### Issue: "VM creation failed"

- Check quota limits in the region
- Try a different VM size: `-BuildVmSize "Standard_D2s_v5"`
- Verify subscription has access to FIPS marketplace images

### Issue: "Image creation taking too long"

- This is normal - image replication can take 10-15 minutes
- Check status: `az sig image-version show --resource-group viya4-image-builder --gallery-name viya4ImageGallery --gallery-image-definition ubuntu-pro-fips-2204 --gallery-image-version 1.0.0`

## Cost Estimate

| Resource | Cost | Duration | Estimated |
|----------|------|----------|-----------|
| Build VM (Standard_D4s_v5) | ~$0.192/hour | ~1 hour | ~$0.20 |
| Image Storage (Standard LRS) | ~$0.05/GB/month | Ongoing | ~$1-2/month |
| Network egress | Minimal | - | <$0.10 |
| **Total one-time** | | | **~$0.30** |
| **Total monthly** | | | **~$1-2** |

**Very affordable!** The build VM is only needed during image creation.

## Updating the Image

To create a new version (e.g., with security patches):

```bash
# Create new version
IMAGE_VERSION="1.1.0" ./create-fips-2204-image.sh

# Update Terraform to use new version
# In your tfvars file:
fips_enabled                = true
use_custom_image_for_fips   = true
custom_node_source_image_id = ".../versions/1.1.0"

# Apply changes
terraform apply
```

AKS will gradually upgrade nodes to the new image version.

## Cleanup

To remove all created resources:

```bash
# Delete the entire resource group (includes gallery and images)
az group delete --name viya4-image-builder --yes

# Or keep gallery but delete old image versions
az sig image-version delete \
  --resource-group viya4-image-builder \
  --gallery-name viya4ImageGallery \
  --gallery-image-definition ubuntu-pro-fips-2204 \
  --gallery-image-version 1.0.0
```

## Next Steps

1. ✅ Run the image creation script
2. ✅ Copy the output Image ID
3. ✅ Update your Terraform `.tfvars` file
4. ✅ Run `terraform apply` to deploy AKS with Ubuntu 22.04
5. ✅ Verify nodes are running Ubuntu 22.04 FIPS

## Need Help?

- This README contains the complete guide for FIPS Ubuntu 22.04 custom images
- View example config: `examples/sample-input-fips-ubuntu-2204.tfvars`
- See configuration reference: `docs/CONFIG-VARS.md`
- Azure Compute Gallery docs: https://learn.microsoft.com/en-us/azure/virtual-machines/azure-compute-gallery
