#!/usr/bin/env bash

# We need to return an error if things don't work
set -e

terraform version -json | jq '.terraform_version' | jq '{"iac_tooling_version": .}'

# The end!
