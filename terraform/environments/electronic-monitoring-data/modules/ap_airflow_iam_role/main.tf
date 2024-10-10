locals {
  account_map = {
    "electronic-monitoring-data-production" : "prod",
    "electronic-monitoring-data-development" : "dev"
    "electronic-monitoring-data-test" : "dev"
  }
  role_name = "airflow-${local.account_map[data.aws_iam_account_alias.current.account_alias]}-${var.role_name_suffix}"
}

data "aws_iam_account_alias" "current" {}

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
      values   = ["system:serviceaccount:airflow:${local.role_name}"]
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
}

resource "aws_iam_policy" "role_ap_airflow" {
  name   = local.role_name
  policy = var.iam_policy_document
}

resource "aws_iam_role_policy_attachment" "role_ap_airflow" {
  role       = aws_iam_role.role_ap_airflow.name
  policy_arn = aws_iam_policy.role_ap_airflow.arn
}
