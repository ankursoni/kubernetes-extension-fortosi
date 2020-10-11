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

# Provision infrastructure on aws

## - Set the values for the variables by writing to the var file - aws-secret.tfvars
``` SH
# for more information on how to configure aws cli: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
# make sure the configured iam user has admin priveleges: https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html 
aws configure

# copy the template variable file
cd infra/aws
cp aws.tfvars aws-secret.tfvars


# prefix, environment and region variables
# these 3 variables help in naming the aws resources
# for e.g., eks cluster name: <PREFIX>-<ENVIRONMENT>-eks01

# substitute the value for <PREFIX> by replacing PLACEHOLDER in the following command:
# PLACEHOLDER e.g. "fortosi" or "cicd" etc.
sed -i 's|<PREFIX>|PLACEHOLDER|g' aws-secret.tfvars

# substitute the value for <ENVIRONMENT> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. "demo" or "play" or "poc" or "dev" or "test" etc.
sed -i 's|<ENVIRONMENT>|PLACEHOLDER|g' aws-secret.tfvars

# substitute the value for <REGION> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. "ap-southeast-2" for Sydney or "ap-southeast-1" for Singapore or "us-east-1" for North Virginia etc.
# Browse https://aws.amazon.com/about-aws/global-infrastructure/regions_az/ for more regions
# run this to know more: "aws ec2 describe-regions -o table"
sed -i 's|<REGION>|PLACEHOLDER|g' aws-secret.tfvars

# substitute the value for <NODE_COUNT> by replacing PLACEHOLDER in the command
# PLACEHOLDER e.g. 2
sed -i 's|<NODE_COUNT>|PLACEHOLDER|g' aws-secret.tfvars

# verify the aws-secret.tfvars file by displaying its content
cat aws-secret.tfvars

# output should be something like this
prefix="fortosi"
environment="demo"
region="ap-southeast-2"
node_count=2

# if there is a correction needed then use text editor 'nano' to update the file and then press ctrl+x after you are done editing
nano aws-secret.tfvars
```

## - Deploy infrastructure
``` SH
cd infra/aws

# initialise terraform providers
terraform init

# execute infrastructure provisioning command
terraform apply -var-file=aws-secret.tfvars

# get kubectl credentials
aws eks --region <REGION> update-kubeconfig --name <PREFIX>-<ENVIRONMENT>-eks01

# patch coredns to use fargate
kubectl patch deployment coredns -n kube-system --type json \
-p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
```

# Browse the EKS cluster
``` SH
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

# wait for deployment to be READY 1/1
kubectl get deployment metrics-server -n kube-system

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

kubectl apply -f eks-admin-service-account.yaml

# copy the token from the output of the following command
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

kubectl proxy

# browse the kubernetes dashboard url on browser and login using the token in previous step
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login
```

# Destroy environment
``` SH
cd infra/aws
terraform destroy -var-file=aws-secret.tfvars
```