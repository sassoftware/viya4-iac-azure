# !NOTE! - These are only a subset of variables.tf provided for sample usage.
# Customize this file to add any variables from 'variables.tf' that you want
# to change (override) their default values .
# Reference `viya4-iac-azure/docs/CONFIG-VARS.md` for more information

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "<prefix-value>" # this is a prefix that you assign for the resources to be created
location = "<azure-location-value>" # e.g., "eastus2"
ssh_public_key = "~/.ssh/id_rsa.pub" # Name of file with public ssh key for connecting to the VMs
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
# **************  RECOMMENDED  VARIABLES  ***************

# Tags for all taggable items in your cluster.
tags = {} # e.g., { "resourceowner" = "<you>@<domain>.<com>", "key1" = "value1", "key2" = "value2" }
