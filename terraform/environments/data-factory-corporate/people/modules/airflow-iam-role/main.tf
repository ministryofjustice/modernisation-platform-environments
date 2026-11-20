# Adapted from ministryofjustice/terraform-aws-moj-data-factory-modules
# modules/airflow-iam-role at 872286b442431969ac3bb8b44410c3e7a53b5c4e; retain resource addresses.
locals {
  airflow_env = {
    "production"    = "prod"
    "preproduction" = "prod"
    "test"          = "test"
    "development"   = "dev"
  }
  env_suffixes = {
    "production"    = ""
    "preproduction" = "-pp"
    "test"          = ""
    "development"   = ""
  }
  mwaa      = "mwaa:${var.airflow_project}${local.env_suffixes[var.environment]}-${var.airflow_workflow}"
  role_name = "airflow-${local.airflow_env[var.environment]}-${var.role_name_suffix}${local.env_suffixes[var.environment]}"
}

data "aws_iam_policy_document" "oidc_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:${local.mwaa}"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${var.oidc_cluster_identifier}:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${var.oidc_cluster_identifier}:aud"
    }
  }
}

resource "aws_iam_role" "airflow_role" {
  name                  = local.role_name
  description           = var.role_description
  assume_role_policy    = data.aws_iam_policy_document.oidc_assume_role_policy.json
  force_detach_policies = true
  max_session_duration  = var.max_session_duration
}

resource "aws_iam_policy" "airflow_role" {
  for_each = {
    for policy_index, policy_document in var.iam_policy_documents : "${local.role_name}-${policy_index}" => policy_document
  }
  name   = each.key
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "airflow_role" {
  for_each   = aws_iam_policy.airflow_role
  role       = aws_iam_role.airflow_role.name
  policy_arn = each.value.arn
}