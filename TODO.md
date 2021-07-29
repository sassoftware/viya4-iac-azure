## Changes for private cluster
- make var to enable private cluster
- on viya4 deployment. patch ingress controller with private ip annotation

## Changes for SAS locked down
- make var for setting outbound_type. Needing for locked down accounts where creating routing tables is not permitted
- make var for postgres vnet_rules. for vpn subscriptions

## Update docs
- Add this line back into CONFIG-VARS.md @ 122
| aks_uai_name | Name of pre-existing user assigned identity, that has Contributor role on resource group, to assign to aks | Required if service principal/managed identity running terraform does not have Owner role on the resource group |
