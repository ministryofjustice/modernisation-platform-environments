locals {
  current_account_id     = data.aws_caller_identity.current.account_id
  current_account_region = data.aws_region.current.name
}


## Glue DB Default Policy
resource "aws_glue_resource_policy" "glue_policy" {
  policy = data.aws_iam_policy_document.glue-policy-data.json
}

data "aws_iam_policy_document" "glue-policy-data" {
  statement {
    actions = [
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateSchema",
      "glue:DeleteSchema",
      "glue:UpdateTable",
    ]
    resources = ["arn:aws:glue:${local.current_account_region}:${local.current_account_id}:*"]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}

# S3 Read Only Policy
resource "aws_iam_policy" "read_s3_read_access_policy" {
  name = "dpr_s3_read_policy"
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
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" : [
          module.s3_demo_bucket[0].bucket.arn,
          "${module.s3_demo_bucket[0].bucket.arn}/*"
        ]
      }
    ]
  })
}