# Upgrading AKS Network Configuration

Microsoft recommends Azure CNI Overlay powered by Cilium as the long-term, highly scalable networking configuration for Azure Kubernetes Service (AKS).

This project incorporates Azure CNI Overlay with Cilium Dataplane as the default network architecture. 

> [!CAUTION]
> If you have an existing cluster deployed with the legacy `kubenet` plugin, **an in-place upgrade strictly via Terraform will force a destructive rebuild of your cluster.** 

To prevent data loss and avoid rebuilding the cluster from scratch, you must perform the network upgrade manually using the Azure CLI *before* applying the new Terraform configuration.

## 1. Prerequisites
- **Kubernetes Version**: Your cluster must be running Kubernetes version 1.27 or higher.
- **Network Policies**: If you use Azure NPM or Calico, you must uninstall/disable it before upgrading.
- **Azure CLI**: You must have Azure CLI version 2.52.0 or later installed.
- **Warning**: This update is irreversible and disruptive. It triggers a rolling reimaging of all nodes in your node pools. Ensure you schedule a maintenance window.

For comprehensive details directly from Microsoft, please read the [official upgrade documentation for network plugins](https://learn.microsoft.com/en-us/azure/aks/upgrade-network-plugin).

## 2. Manual Upgrade Steps via Azure CLI

Use the Azure CLI to forcefully update your cluster's network profile without destroying the cluster object itself.

### Step 1: Update to Azure CNI Overlay
You must supply a new Pod CIDR space since Azure CNI Overlay utilizes its own subnet for pods, functionally isolated from the core VNet nodes.

For example:
```bash
az aks update --resource-group <your-resource-group> --name <your-aks-cluster-name> \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --pod-cidr 10.244.0.0/16
```
*(Note: Ensure the defined pod CIDR does not overlap with your existing VNet subnets.)*

### Step 2: Enable the Cilium Data Plane
Once the first update finishes successfully, apply the Cilium data plane and network policy capabilities.
```bash
az aks update --resource-group <your-resource-group> --name <your-aks-cluster-name> \
  --network-dataplane cilium \
  --network-policy cilium
```

## 3. Synchronize Terraform State
Once your cluster finishes upgrading successfully natively in Azure, you must synchronize your Terraform state so that Terraform's local files are aware of the changes.

1. Ensure your `terraform.tfvars` overrides (if you have them) accurately match the new configuration, or simply let the repository defaults apply automatically:
   ```hcl
   aks_network_plugin      = "azure"
   aks_network_plugin_mode = "overlay"
   aks_network_dataplane   = "cilium"
   aks_network_policy      = "cilium"
   ```
2. Run a standard state refresh against your Azure Environment:
   ```bash
   terraform apply -refresh-only
   ```
   This command pulls the live state directly from Azure into Terraform's local `.tfstate`. Terraform will now see that your cluster is running Azure CNI properly and update its tracked attributes smoothly.
3. Finally, verify the plan:
   ```bash
   terraform plan
   ```
   The plan should display minimal non-destructive changes and notably show that the cluster does not need to be replaced.
