#!/bin/bash
# locally executed script assumes the current/execution directory:
# "cd infra"
# $1 - output log file name w/ extension and full path

terraform init

if [ ! -z "$1" ]
then 
  terraform apply -auto-approve -var-file azurerm-secret.tfvars 2>&1 | tee $1
else
  terraform apply -auto-approve -var-file azurerm-secret.tfvars
fi