#!/usr/bin/env bash

# Copyright © 2020-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

# setup container user
echo "viya4-iac-azure:*:$(id -u):$(id -g):,,,:/viya4-iac-azure:/bin/bash" >> /etc/passwd
echo "viya4-iac-azure:*:$(id -G | cut -d' ' -f 2)" >> /etc/group

if [ -f "/.azure_docker_creds.env" ]; then
    . /.azure_docker_creds.env
fi

export TF_VAR_client_id=$TF_VAR_client_id
export TF_VAR_client_secret=$TF_VAR_client_secret
export TF_VAR_tenant_id=$TF_VAR_tenant_id
export TF_VAR_subscription_id=$TF_VAR_subscription_id

# package - default to .
# test name - default to *
# build tags - default to integration_plan_unit_tests (name pending)
exec go test -v . -run TestDefaults -tags integration_plan_unit_tests