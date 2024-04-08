#!/usr/bin/env bash

# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

# setup container user
echo "viya4-iac-azure:*:$(id -u):$(id -g):,,,:/viya4-iac-azure:/bin/bash" >> /etc/passwd
echo "viya4-iac-azure:*:$(id -G | cut -d' ' -f 2)" >> /etc/group

exec /bin/terraform "$@"
