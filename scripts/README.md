# Quick Start: Creating Ubuntu Pro FIPS 22.04 Custom Image



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
| **Configuration** | `fips_enabled = true` | `fips_enabled = true`<br>`use_custom_image_for_fips = true`<br>`custom_node_source_image_id = "<id>"` |
| **Security Updates** | Automatic (Azure manages) | **Manual (you must rebuild)** |
| **Patching** | Automatic | **Your responsibility** |
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


### Issue: Nodes still show Ubuntu 20.04

**Causes:**
- `use_custom_image_for_fips` not set to `true` in tfvars
- `custom_node_source_image_id` not set correctly in tfvars
- Image ID format is incorrect
- AKS didn't pick up the custom image


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

## Need Help?

- This README contains the complete guide for FIPS Ubuntu 22.04 custom images
- View example config: `examples/sample-input-fips-ubuntu-2204.tfvars`
- See configuration reference: `docs/CONFIG-VARS.md`
- Azure Compute Gallery docs: https://learn.microsoft.com/en-us/azure/virtual-machines/azure-compute-gallery
