## Changes for private cluster
- make var to enable private cluster
- on viya4 deployment. patch ingress controller with private ip annotation

## Changes for SAS locked down
- make var for setting outbound_type. Needing for locked down accounts where creating routing tables is not permitted
- make var for postgres vnet_rules. for vpn subscriptions
