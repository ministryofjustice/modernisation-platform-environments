data "aws_eks_cluster" "apps_and_tools" {
  name = "apps-tools-${local.environment}"
}

data "aws_iam_openid_connect_provider" "apps_and_tools" {
  url = data.aws_eks_cluster.apps_and_tools.identity[0].oidc[0].issuer
}

data "aws_vpc" "dedicated" {
  tags = {
    Name = "${local.application_name}-${local.environment}"
  }
}

data "aws_subnets" "dedicated" {
  for_each = toset(["db", "private", "public"])
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dedicated.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-${each.value}-*"]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.dedicated["private"].ids)
  id       = each.value
}

data "aws_db_subnet_group" "db_subnet_group" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_iam_policy_document" "datahub" {
  statement {
    sid       = "AllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = formatlist("arn:aws:iam::%s:role/${local.environment_configuration.datahub_role}", local.environment_configuration.datahub_target_accounts)
  }
}

data "aws_availability_zones" "available" {}

data "aws_iam_roles" "eks_sso_access_role" {
  name_regex  = "AWSReservedSSO_${local.environment_configuration.eks_sso_access_role}_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
##################################################
# Data Platform Apps and Tools Route 53
##################################################

data "aws_route53_zone" "apps_tools" {
  name         = local.environment_configuration.route53_zone
  private_zone = false
}

##################################################
# Data Platform Apps and Tools Airflow S3
##################################################

data "aws_s3_bucket" "airflow" {
  bucket = local.environment_configuration.airflow_s3_bucket
}

##################################################
# Data Platform Apps and Tools IAM
##################################################



##################################################
# Data Platform Apps and Tools Open Metadata
##################################################

data "aws_secretsmanager_secret_version" "openmetadata_entra_id_client_id" {
  secret_id = "openmetadata/entra-id/client-id"
}

data "aws_secretsmanager_secret_version" "openmetadata_entra_id_tenant_id" {
  secret_id = "openmetadata/entra-id/tenant-id"
}
