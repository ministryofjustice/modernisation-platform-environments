data "aws_vpc_endpoint" "mwaa_webserver" {
  service_name = aws_mwaa_environment.main.webserver_vpc_endpoint_service
}

data "dns_a_record_set" "mwaa_webserver_vpc_endpoint" {
  host = data.aws_vpc_endpoint.mwaa_webserver.dns_entry[0].dns_name
}

# DP VPC
data "aws_vpc" "dp_vpc" {
  tags = {
    "Name" = "${var.networking[0].application}-${local.environment}"
  }
}

data "aws_subnets" "dp_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dp_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].application}-${local.environment}-public*"
  }
}

data "aws_subnet" "dp_private_subnet_a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dp_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].application}-${local.environment}-private-a"
  }
}

data "aws_subnet" "dp_private_subnet_b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dp_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].application}-${local.environment}-private-b"
  }
}

# ACM
data "aws_acm_certificate" "certificate" {
  domain   = local.environment_configuration.route53_zone
  statuses = ["ISSUED"]
}

# EKS
data "aws_eks_cluster" "dp_cluster" {
  name = local.eks_cluster_name
}

data "aws_eks_cluster_auth" "dp_cluster" {
  name = data.aws_eks_cluster.dp_cluster.name
}

# KMS
data "aws_kms_key" "common_secrets_manager_kms" {
  key_id = "alias/secretsmanager/data-platform-${local.environment}/common"
}


data "aws_eks_cluster" "eks" {
  name = local.eks_cluster_name
}

# >>> TEMPORARY (Airflow 3 durability test): START
data "aws_iam_policy_document" "mwaa_bucket" {
  /* Airflow workflow roles: read, write and delete objects under their prefix only */
  dynamic "statement" {
    for_each = local.mwaa_bucket_workflow_role_arns
    content {
      sid    = "WorkflowObjects${replace(title(statement.key), "/[^A-Za-z0-9]/", "")}"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = statement.value
      }
      actions = [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject"
      ]
      resources = ["arn:aws:s3:::mojdp-${local.environment}-mwaa/${statement.key}/*"]
    }
  }

  /* Airflow workflow roles: list their prefix only */
  dynamic "statement" {
    for_each = local.mwaa_bucket_workflow_role_arns
    content {
      sid    = "WorkflowList${replace(title(statement.key), "/[^A-Za-z0-9]/", "")}"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = statement.value
      }
      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::mojdp-${local.environment}-mwaa"]
      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = ["${statement.key}/*"]
      }
    }
  }
}
# <<< TEMPORARY (Airflow 3 durability test): END
