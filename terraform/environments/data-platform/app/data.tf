data "aws_eks_cluster" "cluster" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_route53_zone" "app" {
  name         = "${local.environment_configuration.app_hostname}."
  private_zone = false
}

data "aws_elb_service_account" "current" {}

data "aws_kms_key" "secrets_manager_common" {
  key_id = "alias/secretsmanager/${local.application_name}-${local.environment}/common"
}

data "aws_vpc" "eks" {
  id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
}

data "aws_subnets" "eks_data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-data*"]
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}
