#!/bin/bash
# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

#############################################################################
# Script to create Ubuntu Pro FIPS 22.04 custom image for AKS
# This script creates a custom image in Azure Compute Gallery
#############################################################################

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

#############################################################################
# CONFIGURATION - EDIT THESE VALUES
#############################################################################

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
RESOURCE_GROUP="${RESOURCE_GROUP:-viya4-image-builder}"
GALLERY_NAME="${GALLERY_NAME:-viya4ImageGallery}"
LOCATION="${LOCATION:-eastus}"
IMAGE_DEFINITION="ubuntu-pro-fips-2204"
IMAGE_VERSION="${IMAGE_VERSION:-1.0.0}"

# Build VM configuration
BUILD_VM_NAME="ubuntu-fips-build-vm"
BUILD_VM_SIZE="Standard_D4s_v5"
ADMIN_USERNAME="azureuser"

#############################################################################
# Validate prerequisites
#############################################################################

echo_info "Validating prerequisites..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo_error "Azure CLI is not installed. Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo_error "Not logged into Azure. Run: az login"
    exit 1
fi

# Get subscription ID if not set
if [ -z "$SUBSCRIPTION_ID" ]; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo_info "Using subscription: $SUBSCRIPTION_ID"
fi

# Set subscription
az account set --subscription "$SUBSCRIPTION_ID"

#############################################################################
# Step 1: Accept Marketplace Terms
#############################################################################

echo_info "Step 1: Accepting marketplace terms for Ubuntu Pro FIPS 22.04..."

if az vm image terms accept \
    --urn Canonical:0001-com-ubuntu-pro-jammy-fips:pro-fips-22_04:latest \
    --subscription "$SUBSCRIPTION_ID" &> /dev/null; then
    echo_info "✓ Marketplace terms accepted"
else
    echo_warn "Marketplace terms may already be accepted or failed - continuing anyway"
fi

#############################################################################
# Step 2: Create Resource Group
#############################################################################

echo_info "Step 2: Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."

if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo_warn "Resource group already exists, using existing one"
else
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --tags purpose="custom-aks-images" environment="shared"
    echo_info "✓ Resource group created"
fi

#############################################################################
# Step 3: Create Azure Compute Gallery
#############################################################################

echo_info "Step 3: Creating Azure Compute Gallery '$GALLERY_NAME'..."

if az sig show \
    --resource-group "$RESOURCE_GROUP" \
    --gallery-name "$GALLERY_NAME" &> /dev/null; then
    echo_warn "Gallery already exists, using existing one"
else
    az sig create \
        --resource-group "$RESOURCE_GROUP" \
        --gallery-name "$GALLERY_NAME" \
        --location "$LOCATION" \
        --description "Custom images for Viya4 AKS deployments"
    echo_info "✓ Gallery created"
fi

#############################################################################
# Step 4: Create Image Definition
#############################################################################

echo_info "Step 4: Creating image definition '$IMAGE_DEFINITION'..."

if az sig image-definition show \
    --resource-group "$RESOURCE_GROUP" \
    --gallery-name "$GALLERY_NAME" \
    --gallery-image-definition "$IMAGE_DEFINITION" &> /dev/null; then
    echo_warn "Image definition already exists, using existing one"
else
    az sig image-definition create \
        --resource-group "$RESOURCE_GROUP" \
        --gallery-name "$GALLERY_NAME" \
        --gallery-image-definition "$IMAGE_DEFINITION" \
        --publisher Canonical \
        --offer 0001-com-ubuntu-pro-jammy-fips \
        --sku pro-fips-22_04 \
        --os-type Linux \
        --os-state Generalized \
        --hyper-v-generation V2 \
        --features SecurityType=TrustedLaunch \
        --description "Ubuntu Pro FIPS 22.04 LTS for AKS nodes"
    echo_info "✓ Image definition created"
fi

#############################################################################
# Step 5: Create Build VM
#############################################################################

echo_info "Step 5: Creating build VM '$BUILD_VM_NAME'..."

# Check if VM already exists
if az vm show --resource-group "$RESOURCE_GROUP" --name "$BUILD_VM_NAME" &> /dev/null; then
    echo_error "Build VM '$BUILD_VM_NAME' already exists. Delete it first or use a different name."
    echo_error "To delete: az vm delete --resource-group $RESOURCE_GROUP --name $BUILD_VM_NAME --yes"
    exit 1
fi

# Check for SSH key
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo_error "SSH public key not found at ~/.ssh/id_rsa.pub"
    echo_error "Generate one with: ssh-keygen -t rsa -b 4096"
    exit 1
fi

echo_info "Creating VM from Ubuntu Pro FIPS 22.04 marketplace image..."
VM_ID=$(az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BUILD_VM_NAME" \
    --image Canonical:0001-com-ubuntu-pro-jammy-fips:pro-fips-22_04:latest \
    --size "$BUILD_VM_SIZE" \
    --admin-username "$ADMIN_USERNAME" \
    --ssh-key-values ~/.ssh/id_rsa.pub \
    --public-ip-sku Standard \
    --nsg-rule SSH \
    --tags purpose="image-builder" temporary="true" \
    --query id -o tsv)

echo_info "✓ Build VM created: $VM_ID"

# Get VM public IP
VM_IP=$(az vm show -d \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BUILD_VM_NAME" \
    --query publicIps -o tsv)

echo_info "VM Public IP: $VM_IP"

#############################################################################
# Step 6: Wait for VM to be ready and customize
#############################################################################

echo_info "Step 6: Waiting for VM to be ready (this may take 2-3 minutes)..."

# Wait for SSH to be available
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${ADMIN_USERNAME}@${VM_IP} "echo 'ready'" &> /dev/null; then
        echo_info "✓ VM is ready"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo_info "Waiting for SSH... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 10
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo_error "VM did not become ready in time"
    exit 1
fi

echo_info "Customizing VM (installing packages, configuring system)..."

# Create customization script
cat > /tmp/customize-vm.sh << 'CUSTOMIZE_SCRIPT'
#!/bin/bash
set -e

echo "Starting VM customization..."

# Update system
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install essential packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    wget \
    jq \
    git \
    build-essential \
    apt-transport-https \
    ca-certificates \
    software-properties-common

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install helm
echo "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify FIPS is enabled
echo "Verifying FIPS configuration..."
if [ -f /proc/sys/crypto/fips_enabled ]; then
    FIPS_STATUS=$(cat /proc/sys/crypto/fips_enabled)
    if [ "$FIPS_STATUS" = "1" ]; then
        echo "✓ FIPS is ENABLED"
    else
        echo "⚠ WARNING: FIPS is NOT enabled"
    fi
else
    echo "⚠ WARNING: FIPS status file not found"
fi

# Clean up
echo "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "✓ VM customization complete"
CUSTOMIZE_SCRIPT

# Copy and run customization script
scp -o StrictHostKeyChecking=no /tmp/customize-vm.sh ${ADMIN_USERNAME}@${VM_IP}:/tmp/
ssh -o StrictHostKeyChecking=no ${ADMIN_USERNAME}@${VM_IP} "chmod +x /tmp/customize-vm.sh && /tmp/customize-vm.sh"

echo_info "✓ VM customized successfully"

#############################################################################
# Step 7: Deprovision and Generalize VM
#############################################################################

echo_info "Step 7: Deprovisioning and generalizing VM..."

# Deprovision from within the VM
ssh -o StrictHostKeyChecking=no ${ADMIN_USERNAME}@${VM_IP} \
    "sudo waagent -deprovision+user -force"

echo_info "Waiting 30 seconds for deprovision to complete..."
sleep 30

# Deallocate VM
echo_info "Deallocating VM..."
az vm deallocate \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BUILD_VM_NAME"

# Generalize VM
echo_info "Generalizing VM..."
az vm generalize \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BUILD_VM_NAME"

echo_info "✓ VM prepared for image capture"

#############################################################################
# Step 8: Create Image Version in Gallery
#############################################################################

echo_info "Step 8: Creating image version $IMAGE_VERSION in gallery..."
echo_info "This may take 10-15 minutes..."

VM_RESOURCE_ID=$(az vm show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BUILD_VM_NAME" \
    --query id -o tsv)

az sig image-version create \
    --resource-group "$RESOURCE_GROUP" \
    --gallery-name "$GALLERY_NAME" \
    --gallery-image-definition "$IMAGE_DEFINITION" \
    --gallery-image-version "$IMAGE_VERSION" \
    --target-regions "$LOCATION" \
    --replica-count 1 \
    --managed-image "$VM_RESOURCE_ID"

echo_info "✓ Image version created successfully"

#############################################################################
# Step 9: Get Image ID
#############################################################################

IMAGE_ID=$(az sig image-version show \
    --resource-group "$RESOURCE_GROUP" \
    --gallery-name "$GALLERY_NAME" \
    --gallery-image-definition "$IMAGE_DEFINITION" \
    --gallery-image-version "$IMAGE_VERSION" \
    --query id -o tsv)

#############################################################################
# Step 10: Cleanup Build VM (optional)
#############################################################################

echo_info "Step 9: Cleaning up build VM..."
read -p "Delete build VM '$BUILD_VM_NAME'? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    az vm delete \
        --resource-group "$RESOURCE_GROUP" \
        --name "$BUILD_VM_NAME" \
        --yes \
        --no-wait
    echo_info "✓ Build VM deletion initiated (running in background)"
else
    echo_warn "Build VM kept. Delete manually with: az vm delete --resource-group $RESOURCE_GROUP --name $BUILD_VM_NAME --yes"
fi

#############################################################################
# SUCCESS - Display configuration
#############################################################################

echo ""
echo_info "========================================================================"
echo_info "SUCCESS! Ubuntu Pro FIPS 22.04 custom image created"
echo_info "========================================================================"
echo ""
echo_info "Image Details:"
echo_info "  Resource Group: $RESOURCE_GROUP"
echo_info "  Gallery Name:   $GALLERY_NAME"
echo_info "  Image Name:     $IMAGE_DEFINITION"
echo_info "  Version:        $IMAGE_VERSION"
echo ""
echo_info "Image ID:"
echo "$IMAGE_ID"
echo ""
echo_info "Add this to your Terraform configuration:"
echo ""
echo "  fips_enabled                = true"
echo "  use_custom_image_for_fips   = true"
echo "  custom_node_source_image_id = \"$IMAGE_ID\""
echo ""
echo_info "========================================================================"
