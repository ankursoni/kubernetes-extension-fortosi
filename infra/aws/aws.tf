variable "prefix" {
  default = "fortosi"
}
variable "environment" {
  default = ""
}
variable "region" {
  default = ""
}
variable "node_count" {
  default = 1
}


terraform {
  required_version = ">= 0.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


provider "aws" {
  region = var.region
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-${var.environment}-vpc01"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/${var.prefix}-${var.environment}-eks01" = "shared"
  }
}

resource "aws_security_group" "sg01" {
  name        = "${var.prefix}-${var.environment}-sg01"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "EFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_efs_file_system" "efs01" {
  creation_token = "${var.prefix}-${var.environment}-efs01"
  encrypted      = true
}

resource "aws_efs_mount_target" "emt01" {
  file_system_id  = aws_efs_file_system.efs01.id
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.sg01.id]
}

resource "aws_efs_mount_target" "emt02" {
  file_system_id  = aws_efs_file_system.efs01.id
  subnet_id       = module.vpc.private_subnets[1]
  security_groups = [aws_security_group.sg01.id]
}

output "efs_id" {
  value = aws_efs_file_system.efs01.id
}


resource "aws_eks_cluster" "eks01" {
  name     = "${var.prefix}-${var.environment}-eks01"
  role_arn = aws_iam_role.iamr01.arn
  version  = "1.17"

  vpc_config {
    subnet_ids = [
      module.vpc.private_subnets[0], module.vpc.private_subnets[1],
      module.vpc.public_subnets[0], module.vpc.public_subnets[1]
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iamrpa01,
    aws_iam_role_policy_attachment.iamrpa02
  ]
}

resource "aws_iam_role" "iamr01" {
  name = "${var.prefix}-${var.environment}-iamr01"

  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [{
        Effect: "Allow",
        Principal: {
          Service: "eks.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }]
  })
}

resource "aws_iam_role_policy_attachment" "iamrpa01" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.iamr01.name
}

resource "aws_iam_role_policy_attachment" "iamrpa02" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.iamr01.name
}


resource "aws_eks_node_group" "eksng01" {
  cluster_name    = aws_eks_cluster.eks01.name
  node_group_name = "${var.prefix}-${var.environment}-eksng01"
  node_role_arn   = aws_iam_role.iamr02.arn
  subnet_ids      = [for s in module.vpc.private_subnets : s]
  # instance_types  = ["t2.medium"]

  scaling_config {
    desired_size = var.node_count
    max_size     = var.node_count+1
    min_size     = 1
  }

  launch_template {
    name          = aws_launch_template.lt01.name
    version       = "$Latest"
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
      scaling_config[0].max_size,
      scaling_config[0].min_size,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iamrpa03,
    aws_iam_role_policy_attachment.iamrpa04,
    aws_iam_role_policy_attachment.iamrpa05,
  ]
}

resource "aws_launch_template" "lt01" {
  name          = "${var.prefix}-${var.environment}-lt01"
  instance_type = "t2.medium"
  user_data     = base64encode(<<EOM
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh $${ClusterName} --enable-docker-bridge 'true'
/opt/aws/bin/cfn-signal --exit-code $? \
--stack  $${AWS::StackName} \
--resource NodeGroup  \
--region $${AWS::Region}

--==MYBOUNDARY==--\
EOM
)
}

resource "aws_iam_role" "iamr02" {
  name = "${var.prefix}-${var.environment}-iamr02"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "iamrpa03" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.iamr02.name
}

resource "aws_iam_role_policy_attachment" "iamrpa04" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.iamr02.name
}

resource "aws_iam_role_policy_attachment" "iamrpa05" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.iamr02.name
}


# resource "aws_eks_fargate_profile" "eksfp01" {
#   cluster_name           = aws_eks_cluster.eks01.name
#   fargate_profile_name   = "${var.prefix}-${var.environment}-eksfp01"
#   pod_execution_role_arn = aws_iam_role.iamr03.arn
#   subnet_ids             = [for s in module.vpc.private_subnets : s]

#   selector {
#     namespace = "kube-system"
#   }
#   selector {
#     namespace = "kubernetes-dashboard"
#   }
#   selector {
#     namespace = "default"
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.iamrpa06
#   ]
# }

# resource "aws_iam_role" "iamr03" {
#   name = "${var.prefix}-${var.environment}-iamr03"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "eks-fargate-pods.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "iamrpa06" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
#   role       = aws_iam_role.iamr03.name
# }