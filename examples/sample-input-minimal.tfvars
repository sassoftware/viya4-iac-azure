# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
# to change their default values. 

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "<prefix-value>"
location                                = "<azure-location-value>" # e.g., "useast2"
default_public_access_cidrs             = []  # e.g., ["123.45.6.89/32"]
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }
# ****************  REQUIRED VARIABLES  ****************
