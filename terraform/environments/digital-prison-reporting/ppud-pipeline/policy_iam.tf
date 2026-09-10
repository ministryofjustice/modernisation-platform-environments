# S3 Read Write Policy
data "aws_iam_role" "dataapi_cross_role" {
  count = local.is-test ? 0 : 1
  name  = "dpr-data-api-cross-account-role"
}

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




# S3 Read Write PPUD Policy attachment
resource "aws_iam_role_policy_attachment" "s3_read_write_ppud" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test ? 0 : 1

  role       = data.aws_iam_role.dataapi_cross_role[0].name
  policy_arn = aws_iam_policy.s3_read_write_ppud_policy[0].arn
}

# Glue Catalog Read-only attachment
resource "aws_iam_role_policy_attachment" "glue_catalog_read_only_ppud" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test ? 0 : 1

  role       = data.aws_iam_role.dataapi_cross_role[0].name
  policy_arn = aws_iam_policy.glue_catalog_ppud_read_only_policy[0].arn
}

# Update Analytical Platform Share Policy & Role
data "aws_iam_role" "analytical_platform_share_role" {
  for_each = local.is-development ? local.analytical_platform_share : {}
  name     = "${each.value.target_account_name}-share-role"
}

data "aws_iam_policy_document" "analytical_platform_share_policy_ppud" {
  for_each = local.is-development ? local.analytical_platform_share : {}

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition",
      "glue:GetTags",
      "glue:DeleteDatabase",
      "glue:TagResource",
      "glue:UpdateDatabase"
    ]
    resources = flatten([
      for resource in each.value.resource_shares : [
        "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/${resource.glue_database}",
        formatlist("arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/${resource.glue_database}/%s", resource.glue_tables),
        "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/${resource.glue_database}/*",
        "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog"
      ]
    ])
  }
}

resource "aws_iam_role_policy" "analytical_platform_share_policy_attachment_ppud" {
  for_each = local.is-development ? local.analytical_platform_share : {}

  name   = "${each.value.target_account_name}-share-policy-ppud"
  role   = data.aws_iam_role.analytical_platform_share_role[each.key].name
  policy = data.aws_iam_policy_document.analytical_platform_share_policy_ppud[each.key].json
}
