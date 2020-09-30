variable "prefix" {
  default = "fortio"
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


resource "aws_efs_file_system" "efs01" {
  creation_token = "${var.prefix}-${var.environment}-efs01"
}

resource "aws_efs_file_system" "efs02" {
  creation_token = "${var.prefix}-${var.environment}-efs02"
}


data "aws_vpc" "vpc01" {
  default = true
}

data "aws_subnet_ids" "subnetids01" {
  vpc_id = data.aws_vpc.vpc01.id
}

resource "aws_eks_cluster" "eks01" {
  name     = "${var.prefix}-${var.environment}-eks01"
  role_arn = aws_iam_role.iamr01.arn
  version  = "1.17.9"

  vpc_config {
    subnet_ids = [for s in data.aws_subnet_ids.subnetids01.ids : s]
  }

  depends_on = [
    aws_iam_role_policy_attachment.iamrpa01,
    aws_iam_role_policy_attachment.iamrpa02,
  ]
}
output "endpoint" {
  value = aws_eks_cluster.eks01.endpoint
}
output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks01.certificate_authority[0].data
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
  subnet_ids             = [for s in data.aws_subnet_ids.subnetids01.ids : s]

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