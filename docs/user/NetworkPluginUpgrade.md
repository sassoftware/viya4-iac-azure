# Upgrading AKS Network Configuration

Microsoft recommends Azure CNI Overlay as the long-term, highly scalable networking configuration for Azure Kubernetes Service (AKS).

This project incorporates Azure CNI Overlay as the default network architecture. 

> [!CAUTION]
> If you have an existing cluster deployed with the legacy `kubenet` plugin, **an in-place upgrade strictly via Terraform will force a destructive rebuild of your cluster.** 

To prevent data loss and avoid rebuilding the cluster from scratch, you must perform the network upgrade manually using the Azure CLI *before* applying the new Terraform configuration.

## 1. Prerequisites
- **Kubernetes Version**: Your cluster must be running Kubernetes version 1.27 or higher.
- **Network Policies**: If you use Azure NPM or Calico, you must uninstall/disable it before upgrading.
- **Azure CLI**: You must have Azure CLI version 2.52.0 or later installed.
- **Warning**: This update is irreversible and disruptive. It triggers a rolling reimaging of all nodes in your node pools. Ensure you schedule a maintenance window.

For comprehensive details directly from Microsoft, please read the [official upgrade documentation for network plugins](https://learn.microsoft.com/en-us/azure/aks/update-azure-cni?tabs=kubenet).

## 2. Manual Upgrade Steps via Azure CLI

Use the Azure CLI to forcefully update your cluster's network profile without destroying the cluster object itself.

### Update to Azure CNI Overlay
You must supply a new Pod CIDR space since Azure CNI Overlay utilizes its own subnet for pods, functionally isolated from the core VNet nodes.

For example:
```bash
az aks update --resource-group <your-resource-group> --name <your-aks-cluster-name> \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --pod-cidr 10.244.0.0/16
```
*(Note: Ensure the defined pod CIDR does not overlap with your existing VNet subnets.)*


