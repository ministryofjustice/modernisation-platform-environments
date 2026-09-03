# S3 Read Write Policy
data "aws_iam_role" "dataapi_cross_role" {
  count = local.is-test ? 0 : 1
  name  = "dpr-data-api-cross-account-role"
}

resource "aws_iam_policy" "s3_read_write_ppud_policy" {
  count = local.is-test ? 0 : 1

  name = "${local.environment}_${local.short_name}_s3_read_write_policy"
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

data "aws_iam_policy_document" "glue_catalog_ppud_read_only_policy" {
  count = local.is-test ? 0 : 1

  statement {
    effect = "Deny"
    actions = [
      "glue:DeleteDatabase",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:UpdateTable"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.region}:${local.modernisation_platform_account_id}:database/${local.short_name}-*/*",
      "arn:aws:glue:${data.aws_region.current.region}:${local.modernisation_platform_account_id}:table/${local.short_name}-*/*",
    ]
  }
}



# S3 Read Write PPUD Policy Attachement
resource "aws_iam_role_policy_attachment" "s3_read_write_ppud" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test ? 0 : 1

  role       = data.aws_iam_role.dataapi_cross_role[0].name
  policy_arn = aws_iam_policy.s3_read_write_ppud_policy[0].arn
}

# S3 Read Write PPUD Policy Attachement
resource "aws_iam_policy" "glue_catalog_ppud_read_only" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  count = local.is-test ? 0 : 1

  name = "${local.environment}_${local.short_name}_glue_catalog_read_only"


  policy = data.aws_iam_policy_document.glue_catalog_ppud_read_only_policy[0].json
}

# Glue Catalog Readonly Attachement
resource "aws_iam_role_policy_attachment" "glue_catalog_ppud_read_only" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy
  count = local.is-test ? 0 : 1

  role       = data.aws_iam_role.dataapi_cross_role[0].name
  policy_arn = aws_iam_policy.glue_catalog_ppud_read_only[0].arn
}