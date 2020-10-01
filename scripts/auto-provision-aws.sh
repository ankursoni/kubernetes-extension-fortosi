#!/bin/bash
# locally executed script assumes the current/execution directory:
# "cd infra/aws"
# $1 - output log file name w/ extension and full path

# stop on error
set -e

terraform init

if [ ! -z "$1" ]
then 
  terraform apply -auto-approve -var-file aws-secret.tfvars 2>&1 | tee $1
else
  terraform apply -auto-approve -var-file aws-secret.tfvars
fi