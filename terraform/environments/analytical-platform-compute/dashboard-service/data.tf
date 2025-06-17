data "aws_availability_zones" "available" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# Shared VPC and Subnets
data "aws_vpc" "apc_vpc" {
  tags = {
    "Name" = "${var.networking[0].application}-${local.environment}"
  }
}

data "aws_subnets" "apc_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.apc_vpc.id]
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-private*"
  }
}

data "aws_subnet" "apc_private" {
  for_each = toset(data.aws_subnets.apc_private.ids)
  id       = each.value
}

data "aws_db_subnet_group" "apc_database_subnet_group" {
  name = "${local.application_name}-${local.environment}"
}

# KMS
data "aws_kms_key" "common_secrets_manager_kms" {
  key_id = "alias/secretsmanager/common"
}

# EKS
data "aws_eks_cluster" "eks" {
  name = local.eks_cluster_name
}
