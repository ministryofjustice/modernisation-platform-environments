locals {
  account_map = {
    "production"    = "prod"
    "preproduction" = "prod"
    "test"          = var.new_airflow ? "test" : "dev"
    "development"   = "dev"
  }
  env_suffixes = {
    "production"    = ""
    "preproduction" = "-pp"
    "test"          = ""
    "development"   = ""
  }
  role_name_suffix = var.environment == "preproduction" ? trimsuffix(var.role_name_suffix, "-pp") : var.role_name_suffix
  mwaa             = var.new_airflow ? "mwaa:emds${local.env_suffixes[var.environment]}-${local.role_name_suffix}" : "airflow:${local.role_name}"
  role_name        = "airflow-${local.account_map[var.environment]}-${var.role_name_suffix}"
}

# --------------------------------------------
# oidc assume role policy for airflow
# --------------------------------------------

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
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${var.secret_code}:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${var.secret_code}:aud"
    }
  }
}

# -----------------------------
# define the role
# -----------------------------

resource "aws_iam_role" "role_ap_airflow" {
  name                  = local.role_name
  description           = var.role_description
  assume_role_policy    = data.aws_iam_policy_document.oidc_assume_role_policy.json
  force_detach_policies = true
  max_session_duration  = var.max_session_duration
}

resource "aws_iam_policy" "role_ap_airflow" {
  for_each = {
    for idx, doc in var.iam_policy_documents : "${local.role_name}-${idx}" => doc
  }
  name_prefix = each.key
  policy      = each.value
}

resource "aws_iam_role_policy_attachment" "role_ap_airflow" {
  for_each   = aws_iam_policy.role_ap_airflow
  role       = aws_iam_role.role_ap_airflow.name
  policy_arn = each.value.arn
}
