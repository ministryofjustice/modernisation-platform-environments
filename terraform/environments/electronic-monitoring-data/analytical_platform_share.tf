locals {
  analytical_platform_share = can(local.application_data.accounts[local.environment].analytical_platform_share) ? { for share in local.application_data.accounts[local.environment].analytical_platform_share : share.target_account_name => share } : {}
  enable_dbt_k8s_secrets    = local.application_data.accounts[local.environment].enable_dbt_k8s_secrets
  dbt_k8s_secrets_placeholder = {
    oidc_cluster_identifier = "placeholder"
  }
}

# Source Analytics DBT Secrets
data "aws_secretsmanager_secret" "dbt_secrets" {
  name = aws_secretsmanager_secret.dbt_secrets[0].id

  depends_on = [aws_secretsmanager_secret_version.dbt_secrets]
}

data "aws_secretsmanager_secret_version" "dbt_secrets" {
  secret_id = data.aws_secretsmanager_secret.dbt_secrets.id

  depends_on = [aws_secretsmanager_secret.dbt_secrets]
}


# Retrieves the source role of terraform's current caller identity
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_iam_roles" "data_engineering_roles" {
  name_regex = "AWSReservedSSO_modernisation-platform-data-eng*"
}

## DBT Analytics EKS Cluster Identifier
# PlaceHolder Secrets
resource "aws_secretsmanager_secret_version" "dbt_secrets" {
  count = local.enable_dbt_k8s_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.dbt_secrets[0].id
  secret_string = jsonencode(local.dbt_k8s_secrets_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.dbt_secrets]
}

resource "aws_secretsmanager_secret" "dbt_secrets" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  count = local.enable_dbt_k8s_secrets ? 1 : 0

  name = "external/analytics_platform/k8s_dbt_auth"

  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    {
      Name          = "external/cloud_platform/k8s_auth"
      Resource_Type = "Secrets"
      Source        = "Analytics-Platform"
      Jira          = "DPR2-751"
    }
  )
}

# TLS Certificate for OIDC URL, DBT K8s Platform
data "tls_certificate" "dbt_analytics" {
  url = "https://oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}"
}


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
  #checkov:skip=CKV_AWS_61:Ensure IAM policies does not allow data exfiltration
  #checkov:skip=CKV_AWS_60:Ensure IAM role allows only specific services or principals to assume it
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  name                  = "${local.environment_shorthand}-data-api-cross-account-role"
  description           = "Data API Cross Account Role"
  assume_role_policy    = data.aws_iam_policy_document.dataapi_cross_assume.json
  force_detach_policies = true

  tags = merge(
    local.tags,
    {
      Name           = "${local.environment_shorthand}-data-api-cross-account-role"
      Resource_Type  = "iam"
      Jira           = "DPR2-751"
      Resource_Group = "Front-End"
    }
  )
}


# LakeFormation Data Access
# Policy Document

data "aws_iam_policy_document" "lake_formation_data_access" {
  statement {
    actions = [
      "lakeformation:GetDataAccess"
    ]
    resources = [
      "*"
    ]
  }
}

# Lake Formation Data Access Attachement
resource "aws_iam_role_policy_attachment" "lake_formation_data_access" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.lake_formation_data_access.arn
}

resource "aws_iam_policy" "lake_formation_data_access" {
  name        = "${local.environment_shorthand}-lake-formation-data-access"
  description = "LakeFormation Get Data Access Policy"
  policy      = data.aws_iam_policy_document.lake_formation_data_access.json
}

# Analytical Platform Share Policy & Role

data "aws_iam_policy_document" "analytical_platform_share_policy" {
  for_each = local.analytical_platform_share

  statement {
    effect = "Allow"
    actions = [
      "lakeformation:GrantPermissions",
      "lakeformation:RevokePermissions",
      "lakeformation:BatchGrantPermissions",
      "lakeformation:BatchRevokePermissions",
      "lakeformation:RegisterResource",
      "lakeformation:DeregisterResource",
      "lakeformation:ListPermissions",
      "lakeformation:DescribeResource",

    ]
    resources = [
      #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
      "arn:aws:lakeformation:${data.aws_region.current.name}:${local.env_account_id}:catalog:${local.env_account_id}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::${local.env_account_id}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"
    ]
  }
  # Needed for LakeFormationAdmin to check the presense of the Lake Formation Service Role
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRolePolicy",
      "iam:GetRole"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ram:CreateResourceShare",
      "ram:DeleteResourceShare"
    ]
    resources = [
      "arn:aws:ram:${data.aws_region.current.name}:${local.env_account_id}:resource-share/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition"
    ]
    resources = flatten([
      for resource in each.value.resource_shares : [
        "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/${resource.glue_database}",
        formatlist("arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/${resource.glue_database}/%s", resource.glue_tables),
        "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog"
      ]
    ])
  }
}

resource "aws_iam_role" "analytical_platform_share_role" {
  for_each = local.analytical_platform_share

  name = "${each.value.target_account_name}-share-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # In case consumer has a central location for terraform state storage that isn't the target account.
          AWS = "arn:aws:iam::${try(each.value.assume_account_id, each.value.target_account_id)}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "analytical_platform_share_policy_attachment" {
  for_each = local.analytical_platform_share

  name   = "${each.value.target_account_name}-share-policy"
  role   = aws_iam_role.analytical_platform_share_role[each.key].name
  policy = data.aws_iam_policy_document.analytical_platform_share_policy[each.key].json
}

# ref: https://docs.aws.amazon.com/lake-formation/latest/dg/cross-account-prereqs.html
resource "aws_iam_role_policy_attachment" "analytical_platform_share_policy_attachment" {
  for_each = local.analytical_platform_share

  role       = aws_iam_role.analytical_platform_share_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
}


# resource "aws_lakeformation_data_lake_settings" "lake_formation" {
#   admins = flatten([[for share in local.analytical_platform_share : aws_iam_role.analytical_platform_share_role[share.target_account_name].arn], data.aws_iam_session_context.current.issuer_arn, try(one(data.aws_iam_roles.data_engineering_roles.arns), [])])

#   # ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_data_lake_settings#principal
#   create_database_default_permissions {
#     # These settings should replicate current behaviour: LakeFormation is Ignored
#     permissions = ["ALL"]
#     principal   = "IAM_ALLOWED_PRINCIPALS"
#   }

#   create_table_default_permissions {
#     # These settings should replicate current behaviour: LakeFormation is Ignored
#     permissions = ["ALL"]
#     principal   = "IAM_ALLOWED_PRINCIPALS"
#   }
# }
