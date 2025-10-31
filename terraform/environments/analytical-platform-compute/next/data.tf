# Networking
data "aws_vpc" "main" {
  tags = {
    "Name" = local.our_vpc_name
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-private*"
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)

  id = each.value
}

data "aws_db_subnet_group" "main" {
  name = local.db_subnet_group_name
}

# KMS
data "aws_kms_key" "secrets_manager_common" {
  key_id = "alias/secretsmanager/common"
}

# EKS
data "aws_eks_cluster" "cluster" {
  name = local.eks_cluster_name
}
