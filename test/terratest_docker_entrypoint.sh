#!/usr/bin/env bash

# Copyright © 2020-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

# Print out arguments
terratest_help() {
  echo "Usage: terratest_docker_entrypoint.sh [OPTIONS]"
  echo "Options:"
  echo "  -p, --package=PACKAGE        The package to test. Default is '.'"
  echo "  -t, --testname=TEST          The name of the test to run. Default is 'TestDefaults'"
  echo "  -b, --build-tags=TAGS        The build tags to use. Default is 'integration_plan_unit_tests'"
  echo "  -v, --verbose                Run the tests in verbose mode"
  echo "  -h, --help                   Display this help message"
}

# setup container user
echo "viya4-iac-azure:*:$(id -u):$(id -g):,,,:/viya4-iac-azure:/bin/bash" >> /etc/passwd
echo "viya4-iac-azure:*:$(id -G | cut -d' ' -f 2)" >> /etc/group

for i in "$@"; do
  case $i in
    -p=*|--package=*)
      PACKAGE="${i#*=}"
      shift # past argument=value
      ;;
    -t=*|--testname=*)
      TEST="${i#*=}"
      shift # past argument=value
      ;;
    -b=*|--build-tags=*)
      TAGS="${i#*=}"
      shift # past argument=value
      ;;
    -v|--verbose)
      VERBOSE=-v
      shift # past argument with no value
      ;;
    -h|--help)
      terratest_help
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $i"
      terratest_help
      exit 1
      ;;
    *)
      ;;
  esac
done

# Set the defaults if the variables are not set
if [ -z "$PACKAGE" ]; then
  PACKAGE="."
fi
if [ -z "$TEST" ]; then
  TEST="TestDefaults"
fi
if [ -z "$TAGS" ]; then
  TAGS="integration_plan_unit_tests"
fi
if [ -z "$VERBOSE" ]; then
  VERBOSE=""
fi

# If the credentials file exists, source it. Otherwise, the environment variables
# will be set by the command line arguments.
if [ -f "/.azure_docker_creds.env" ]; then
    . /.azure_docker_creds.env
fi

# Export the varibles that were sourced
export TF_VAR_client_id=$TF_VAR_client_id
export TF_VAR_client_secret=$TF_VAR_client_secret
export TF_VAR_tenant_id=$TF_VAR_tenant_id
export TF_VAR_subscription_id=$TF_VAR_subscription_id

# Run the tests
echo "Running 'go test $VERBOSE $PACKAGE -run $TEST -tags $TAGS'"
exec go test $VERBOSE $PACKAGE -run $TEST -tags $TAGS | tee test_output.log

# Parse the results
terratest_log_parser -testlog test_output.log -outputdir test_output
cd test_output
go run parse_results.go
