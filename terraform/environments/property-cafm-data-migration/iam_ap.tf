locals {
  analytical_platform_compute_environments = {
    development = {
      eks_oidc_id = "1972AFFBD0701A0D1FD291E34F7D1287"
    }
    preproduction = {
      eks_oidc_id = "9FAFCA50C4DA68A8E75FD21EA53A4F2B"
    }
    production = {
      eks_oidc_id = "801920EDEF91E3CAB03E04C03A2DE2BB"
    }
  }
}

data "tls_certificate" "analytical_platform_compute" {
  url = "https://oidc.eks.eu-west-2.amazonaws.com/id/${local.analytical_platform_compute_environments[local.environment].eks_oidc_id}"
}

resource "aws_iam_openid_connect_provider" "analytical_platform_compute" {
  url             = "https://oidc.eks.eu-west-2.amazonaws.com/id/${local.analytical_platform_compute_environments[local.environment].eks_oidc_id}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.analytical_platform_compute.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "cadet_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.analytical_platform_compute.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Use dev runner for all non-prod envs, only use prod runner for prod env
    condition {
      test     = "StringEquals"
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${local.analytical_platform_compute_environments[local.environment].eks_oidc_id}:sub"
        values   = ["system:serviceaccount:actions-runners:actions-runner-mojas-create-a-derived-table-property-${local.environment == "production" ? "production" : "development"}"]
    }

    condition {
      test     = "StringEquals"
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${local.analytical_platform_compute_environments[local.environment].eks_oidc_id}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "create_a_derived_table" {
  #checkov:skip=CKV_AWS_61:Ensure IAM policies does not allow data exfiltration

  name                  = "create-a-derived-table"
  description           = "Role to allow CADET to run models"
  assume_role_policy    = data.aws_iam_policy_document.cadet_assume_role_policy.json
  force_detach_policies = true
}

data "aws_iam_policy_document" "create_a_derived_table_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lakeformation:*",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:GetPartition",
      "glue:GetPartitions",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "create_a_derived_table_policy" {
  name        = "create-a-derived-table-policy"
  description = "Policy for Lake Formation, Glue, and S3 access for create_a_derived_table role"
  policy      = data.aws_iam_policy_document.create_a_derived_table_policy.json
}

resource "aws_iam_role_policy_attachment" "create_a_derived_table_policy_attachment" {
  role       = aws_iam_role.create_a_derived_table.name
  policy_arn = aws_iam_policy.create_a_derived_table_policy.arn
}
