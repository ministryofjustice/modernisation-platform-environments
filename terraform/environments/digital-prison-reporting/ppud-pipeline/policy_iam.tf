# S3 Read Write Policy
resource "aws_iam_policy" "s3_read_write_ppud_policy" {
  count = local.is-test ? 0 : 1

  name = "${local.short_name}_s3_read_write_policy_${local.environment}"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowUserToSeeBucketListInTheConsole",
        "Action" : ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::*"]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.short_name}-*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*Object",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.short_name}-*/*",
          "arn:aws:s3:::${local.short_name}-*",
        ]
      },
      {
        "Effect" : "Deny",
        "Action" : [
          "s3:DeleteObject",
          "s3:PutObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.short_name}-*/*",
          "arn:aws:s3:::${local.short_name}-*",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "glue_catalog_ppud_read_only_policy" {
  count = local.is-test ? 0 : 1

  name = "${local.short_name}_glue_catalog_read_only_policy_${local.environment}"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Action" : [
          "glue:DeleteDatabase",
          "glue:UpdateDatabase",
          "glue:CreateTable",
          "glue:DeleteTable",
          "glue:UpdateTable"
        ],
        "Resource" : [
          "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/${local.short_name}_${local.short_name_environment}",
          "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/${local.short_name}_${local.short_name_environment}/*"
        ]
      },
    ]
  })
}

## Role
## CrossAccount DataAPI Cross Account Role,
# CrossAccount DataAPI Assume Policy
data "aws_iam_policy_document" "airflow_assume" {
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

  count = local.is-production ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.cluster[0].arn]
    }

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}:aud"
    }

    condition {
      test = "StringEquals"

      values = [
        "system:serviceaccount:mwaa:probation-ppud-derived"
      ]

      variable = "oidc.eks.eu-west-2.amazonaws.com/id/${jsondecode(data.aws_secretsmanager_secret_version.dbt_secrets.secret_string)["oidc_cluster_identifier"]}:sub"
    }
  }
}

resource "aws_iam_role" "airflow_cross_account" {
  count = local.is-production ? 1 : 0

  name = "probation-ppud-derived-cross-account"

  assume_role_policy = data.aws_iam_policy_document.airflow_assume[0].json
}

data "aws_iam_policy_document" "airflow_assume_dataapi" {
  count = local.is-production ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      data.aws_iam_role.dataapi_cross_role[0].arn
    ]
  }
}

resource "aws_iam_policy" "airflow_assume_dataapi" {
  count = local.is-production ? 1 : 0

  name = "probation-ppud-derived-assume-dataapi"

  policy = data.aws_iam_policy_document.airflow_assume_dataapi[0].json
}

resource "aws_iam_role_policy_attachment" "airflow_cross_account" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-production ? 1 : 0

  role       = data.aws_iam_role.dataapi_cross_role[0].name
  policy_arn = aws_iam_policy_document.airflow_assume_dataapi[0].arn
}



# S3 Read Write PPUD Policy attachment
resource "aws_iam_role_policy_attachment" "s3_read_write_ppud" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test ? 0 : 1

  role       = aws_iam_role.airflow_cross_account[0].name
  policy_arn = aws_iam_policy.airflow_assume_dataapi[0].arn
}

# Glue Catalog Read-only attachment
resource "aws_iam_role_policy_attachment" "glue_catalog_read_only_ppud" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test ? 0 : 1

  role       = data.aws_iam_role.dataapi_cross_role[0].name
  policy_arn = aws_iam_policy.glue_catalog_ppud_read_only_policy[0].arn
}
