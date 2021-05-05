#!/usr/bin/env bash
set -e

# setup container user
echo "viya4-iac-azure:*:$(id -u):$(id -g):,,,:/viya4-iac-azure:/bin/bash" >> /etc/passwd
echo "viya4-iac-azure:*:$(id -G | cut -d' ' -f 2)" >> /etc/group

exec /bin/terraform "$@"
