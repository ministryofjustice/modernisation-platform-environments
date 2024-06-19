### Cross Account Resources

## OIDC, OpenID Connect
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.dbt_analytics.certificates[0].sha1_fingerprint]
  url             = "https://oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}"
}

## Role
## CrossAccount DataAPI Cross Account Role, 
# CrossAccount DataAPI Assume Policy
data "aws_iam_policy_document" "dataapi_cross_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754256621582:root"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:actions-runners:actions-runner-mojas-create-a-derived-table-dpr"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}:aud"
    }
  }
}

# CrossAccount DataAPI Role
resource "aws_iam_role" "dataapi_cross_role" {
  name                  = "${local.project}-data-api-cross-account-role"
  description           = "Data API Cross Account Role"
  assume_role_policy    = data.aws_iam_policy_document.dataapi_cross_assume.json
  force_detach_policies = true

  tags = merge(
    local.tags,
    {
      Name           = "${local.project}-data-api-cross-account-role"
      Resource_Type  = "iam"
      Jira           = "DPR2-751"
      Resource_Group = "Front-End"
    }
  )
}

# CrossAccount DataAPI Role/Policy Attachement
resource "aws_iam_role_policy_attachment" "redshift_dataapi" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.redshift_dataapi_cross_policy.arn
}

# Athena API Role/Policy Attachement
resource "aws_iam_role_policy_attachment" "athena_api" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.athena_api_cross_policy.arn
}

# S3 Read Write Policy Attachement
resource "aws_iam_role_policy_attachment" "s3_read_write" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

# KMS Policy Attachement
resource "aws_iam_role_policy_attachment" "kms_read_access_policy" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.kms_read_access_policy.arn
}

# Glue Catalog Readonly Attachement
resource "aws_iam_role_policy_attachment" "glue_catalog_readonly" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.glue_catalog_readonly.arn
}

