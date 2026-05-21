data "aws_eks_cluster" "cluster" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}

data "aws_iam_openid_connect_provider" "cluster" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

data "aws_vpc" "eks" {
  id = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
}

data "aws_subnets" "eks-data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-data*"]
  }
}

data "aws_secretsmanager_secret_version" "litellm_license" {
  secret_id = module.litellm_license_secret.secret_id
}

data "aws_secretsmanager_secret_version" "litellm_entra_id" {
  secret_id = module.litellm_entra_id_secret.secret_id
}

