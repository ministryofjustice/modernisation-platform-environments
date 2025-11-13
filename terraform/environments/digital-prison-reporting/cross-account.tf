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
  #checkov:skip=CKV_AWS_110:Ensure IAM policies does not allow privilege escalation
  #checkov:skip=CKV_AWS_358:OIDC trust policies only allows actions from a specific known organization Already
  #checkov:skip=CKV_AWS_107:Ensure IAM policies does not allow credentials exposure
  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_1
  #checkov:skip=CKV_AWS_283
  #checkov:skip=CKV_AWS_49
  #checkov:skip=CKV_AWS_108

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
      values   = ["system:serviceaccount:actions-runners:actions-runner-mojas-create-a-derived-table-dpr${local.environment_configuration.analytical_platform_runner_suffix}"]
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
  #checkov:skip=CKV_AWS_61:Ensure IAM policies does not allow data exfiltration
  #checkov:skip=CKV_AWS_60:Ensure IAM role allows only specific services or principals to assume it
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  name                  = "${local.project}-data-api-cross-account-role"
  description           = "Data API Cross Account Role"
  assume_role_policy    = data.aws_iam_policy_document.dataapi_cross_assume.json
  force_detach_policies = true

  tags = merge(
    local.all_tags,
    {
      dpr-name           = "${local.project}-data-api-cross-account-role"
      dpr-resource-type  = "iam"
      dpr-jira           = "DPR2-751"
      dpr-resource-group = "Front-End"
    }
  )
}

# CrossAccount RDS Role/Policy Attachement
resource "aws_iam_role_policy_attachment" "rds" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.rds_cross_policy.arn
}

# CrossAccount DataAPI Role/Policy Attachement
resource "aws_iam_role_policy_attachment" "redshift_dataapi" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.redshift_dataapi_cross_policy.arn
}

# Athena API Role/Policy Attachement
resource "aws_iam_role_policy_attachment" "athena_api" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.athena_api_cross_policy.arn
}

# S3 Read Write Policy Attachement
resource "aws_iam_role_policy_attachment" "s3_read_write" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

# KMS Policy Attachement
resource "aws_iam_role_policy_attachment" "kms_read_access_policy" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.kms_read_access_policy.arn
}

# Glue Catalog Readonly Attachement
resource "aws_iam_role_policy_attachment" "glue_catalog_readonly" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.glue_catalog_readonly.arn
}

# Lake Formation Data Access Attachement
resource "aws_iam_role_policy_attachment" "lake_formation_data_access" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.lake_formation_data_access.arn
}

# Lake formation list permissions
resource "aws_iam_role_policy_attachment" "lake_formation_permissions_management" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.lake_formation_permissions_management.arn
}

# Lake Formation Tag Management Attachement
resource "aws_iam_role_policy_attachment" "lake_formation_tag_management" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.lake_formation_tag_management.arn
}


