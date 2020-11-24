#!/usr/bin/env bash

# We need to return an error if things don't work
set -e

function check_deps() {
  test -f $(which jq) || error_exit "jq command not detected in path, please install it"
}

check_deps

TERRAFORM_INFO="$(terraform version -json)"
TERRAFORM_VERSION=$(echo $TERRAFORM_INFO | jq .terraform_version )
TERRAFORM_REVISION=$(echo $TERRAFORM_INFO | jq .terraform_revision )
PROVIDER_SELECTIONS=$(echo $TERRAFORM_INFO | jq -c .provider_selections )
TERRAFORM_OUTDATED=$(echo $TERRAFORM_INFO | jq .terraform_outdated )
# echo "${TERRAFORM_INFO | jq "

jq -n \
  --arg terraform_version "$TERRAFORM_VERSION" \
  --arg terraform_revision "$TERRAFORM_REVISION" \
  --arg terraform_outdated "$TERRAFORM_OUTDATED" \
  --arg provider_selections "$PROVIDER_SELECTIONS" \
 '{"terraform_version":$terraform_version, "terraform_revision":$terraform_revision, "terraform_outdated":$terraform_outdated, "provider_selections":$provider_selections}'

# echo "$(echo $TERRAFORM_INFO |jq -cr)"
# The end!
