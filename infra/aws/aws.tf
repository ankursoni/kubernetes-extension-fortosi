variable "prefix" {
  default = "fortio"
}
variable "environment" {
  default = ""
}
variable "region" {
  default = ""
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


data "aws_vpc" "vpc01" {
  default = true
}

data "aws_subnet_ids" "subnetids01" {
  vpc_id = data.aws_vpc.vpc01.id
}

resource "aws_eks_cluster" "eks01" {
  name     = "${var.prefix}-${var.environment}-eks01"
  role_arn = aws_iam_role.iamr01.arn

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

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "iamrpa01" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.iamr01.name
}

resource "aws_iam_role_policy_attachment" "iamrpa02" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.iamr01.name
}