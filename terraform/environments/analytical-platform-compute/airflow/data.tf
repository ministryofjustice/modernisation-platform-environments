data "aws_availability_zones" "available" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

# Shared VPC and Subnets
data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_subnets" "shared_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private*"
  }
}

data "aws_subnet" "shared_private_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "shared_private_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "shared_private_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}c"
  }
}

data "aws_vpc_endpoint" "mwaa_webserver" {
  service_name = aws_mwaa_environment.main.webserver_vpc_endpoint_service
}

data "dns_a_record_set" "mwaa_webserver_vpc_endpoint" {
  host = data.aws_vpc_endpoint.mwaa_webserver.dns_entry[0].dns_name
}

# APC VPC
data "aws_vpc" "apc_vpc" {
  tags = {
    "Name" = "${var.networking[0].application}-${local.environment}"
  }
}

data "aws_subnets" "apc_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.apc_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].application}-${local.environment}-public*"
  }
}

data "aws_subnets" "apc_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.apc_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].application}-${local.environment}-private*"
  }
}

# ACM
data "aws_acm_certificate" "certificate" {
  domain   = local.environment_configuration.route53_zone
  statuses = ["ISSUED"]
}

# Kubernetes
data "kubernetes_namespace" "actions_runner" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  metadata {
    name = "actions-runner"
  }
}

# Secrets manager
data "aws_secretsmanager_secret" "actions_runners_token_apc_self_hosted_runners_secret" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  name = "actions-runners/token/apc-self-hosted-runners"
}

data "aws_secretsmanager_secret_version" "actions_runners_token_apc_self_hosted_runners_github_app" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.actions_runners_token_apc_self_hosted_runners_secret[0].id
}

# EKS
data "aws_eks_cluster" "apc_cluster" {
  name = local.eks_cluster_name
}

# KMS
data "aws_kms_key" "common_secrets_manager_kms" {
  key_id = "alias/secretsmanager/common"
}
