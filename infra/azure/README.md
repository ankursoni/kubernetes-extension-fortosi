# Install terraform
``` SH
{
  wget https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.3_linux_amd64.zip
  unzip terraform_0.13.3_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
  rm terraform_0.13.3_linux_amd64.zip
}

# verify
terraform -v
```

# Provision infrastructure on azure

## - Set the values for the variables by writing to the var file - azure-secret.tfvars
``` SH
az login
az account list
# note the id as <SUBSCRIPTION_ID> and tenantId as <TENANT_ID> from the output of previous command

# generate an azure service principal with contributor permissions, if you don't already have one:
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"
# note the appId as <CLIENT_ID> and password as <CLIENT_SECRET> from the output of previous command

# assign user access administrator role permissions
az ad sp show --id "<appId from previous step>"
az role assignment create --role "User Access Administrator" --assignee-object-id "<objectId from previous step>"


# copy the template variable file
cd infra/azure
cp azure.tfvars azure-secret.tfvars


# subscription, tenant and service principal variables

# substitute the value for <SUBSCRIPTION_ID> by replacing PLACEHOLDER in the following command:
sed -i 's|<SUBSCRIPTION_ID>|PLACEHOLDER|g' azure-secret.tfvars
# for e.g., the command to substitute the value for <SUBSCRIPTION_ID> with 794a7d2a-565a-4ebd-8dd9-0439763e6b55 as PLACEHOLDER looks like this:
# sed -i 's|<SUBSCRIPTION_ID>|794a7d2a-565a-4ebd-8dd9-0439763e6b55|g' azure-secret.tfvars

# substitute the value for <TENANT_ID> by replacing PLACEHOLDER in the following command:
sed -i 's|<TENANT_ID>|PLACEHOLDER|g' azure-secret.tfvars

# substitute the value for <CLIENT_ID> by replacing PLACEHOLDER in the following command:
sed -i 's|<CLIENT_ID>|PLACEHOLDER|g' azure-secret.tfvars

# substitute the value for <CLIENT_SECRET> by replacing PLACEHOLDER in the command
sed -i 's|<CLIENT_SECRET>|PLACEHOLDER|g' azure-secret.tfvars


# prefix, environment and location variables
# these 3 variables help in naming the azure resources
# for e.g., resource group name: <PREFIX>-<ENVIRONMENT>-rg01
# for e.g., aks cluster name: <PREFIX>-<ENVIRONMENT>-aks01

# substitute the value for <PREFIX> by replacing PLACEHOLDER in the following command:
# PLACEHOLDER e.g. "fortosi" or "cicd" etc.
sed -i 's|<PREFIX>|PLACEHOLDER|g' azure-secret.tfvars

# substitute the value for <ENVIRONMENT> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. "demo" or "play" or "poc" or "dev" or "test" etc.
sed -i 's|<ENVIRONMENT>|PLACEHOLDER|g' azure-secret.tfvars

# substitute the value for <LOCATION> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. "australiaeast" or "southeastasia" or "centralus" or "westeurope" etc.
# run this command to know more:
# az account list-locations -o table
sed -i 's|<LOCATION>|PLACEHOLDER|g' azure-secret.tfvars

# substitute the value for <NODE_VM_SIZE> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. "Standard_B2s" or "Standard_B2ms" or "Standard_DS2_v2" etc. with ssd disk capabilities indicated by 's'
# run this command to know more:
# az vm list-sizes --location "<LOCATION>" -o table
sed -i 's|<NODE_VM_SIZE>|PLACEHOLDER|g' azure-secret.tfvars

# substitute the value for <NODE_COUNT> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. 1 or 2 etc.
# choose 1 if you are learning and then later scale out more from azure portal
sed -i 's|<NODE_COUNT>|PLACEHOLDER|g' azure-secret.tfvars

# verify the auzure-secret.tfvars file by displaying its content
cat azure-secret.tfvars

# output should be something like this
subscription_id="794a7d2a-565a-4ebd-8dd9-0439763e6b55"
tenant_id="<removed as secret>" 
client_id="<removed as secret>"
client_secret="<removed as secret>"
prefix="fortosi"
environment="demo"
location="australiaeast"
vm_size="Standard_B2s"
vm_count=1

# if there is a correction needed then use text editor 'nano' to update the file and then press ctrl+x after you are done editing
nano azure-secret.tfvars
```

## - Deploy infrastructure
``` SH
cd infra/azure

# initialise terraform providers
terraform init

# execute infrastructure provisioning command
terraform apply -var-file=azure-secret.tfvars

# if terraform throws any error, it may be due to dns name conflicts with already deployed infrastructure in the chosen azure location.
# try to workaround these errors by changing the values of the variable - prefix or environment or location in the variable values file - azure-secret.tfvars
# use text editor 'nano' to update the file and then press ctrl+x after you are done editing
nano azure-secret.tfvars
```

# Browse the AKS cluster
``` SH
az aks get-credentials -n <PREFIX>-<ENVIRONMENT>-aks01 -g <PREFIX>-<ENVIRONMENT>-rg01
az aks browse -n <PREFIX>-<ENVIRONMENT>-aks01 -g <PREFIX>-<ENVIRONMENT>-rg01
```

# Destroy environment
``` SH
cd infra/azure
terraform destroy -var-file=azure-secret.tfvars
```