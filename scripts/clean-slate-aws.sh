#!/bin/bash
# locally executed script assumes the current/execution directory:
# "cd infra/aws"
# $1 - enable terraform state cleanup

# stop on error
set -e

if [ -s terraform.tfstate ]
then
  echo -e "\nTerraform destroy"
  terraform destroy -auto-approve -var-file=aws-secret.tfvars
fi

if [ ! -z "$1" ] && ( $1 )
then
  echo -e "\nDeleting terraform state"
  rm terraform.tfstate* -rf

  echo -e "\nDeleting terraform providers"
  rm .terraform -rf
fi