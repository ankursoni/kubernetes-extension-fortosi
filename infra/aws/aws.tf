variable "prefix" {
  default = "fortosi"
}
variable "environment" {
  default = ""
}
variable "region" {
  default = ""
}
variable "cicd_namespace" {
  default = "jenkins"
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

  tags = {
    "kubernetes.io/cluster/${var.prefix}-${var.environment}-eks01" = "shared"
  }
}

resource "aws_efs_file_system" "efs01" {
  creation_token = "${var.prefix}-${var.environment}-efs01"
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
    aws_iam_role.iamr01,
    aws_iam_role_policy_attachment.iamrpa01,
    aws_iam_role_policy_attachment.iamrpa02
  ]
}

output "efs_id" {
  value = aws_efs_file_system.efs01.id
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

resource "aws_eks_fargate_profile" "eksfp01" {
  cluster_name           = aws_eks_cluster.eks01.name
  fargate_profile_name   = "${var.prefix}-${var.environment}-eksfp01"
  pod_execution_role_arn = aws_iam_role.iamr02.arn
  subnet_ids             = [for s in module.vpc.private_subnets : s ]

  selector {
    namespace = "kube-system"
  }
  selector {
    namespace = "kubernetes-dashboard"
  }
  selector {
    namespace = "default"
  }
  selector {
    namespace = var.cicd_namespace
  }
}

resource "aws_iam_role" "iamr02" {
  name = "${var.prefix}-${var.environment}-iamr02"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "iamrpa03" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.iamr02.name
}