locals {
  current_account_id     = data.aws_caller_identity.current.account_id
  current_account_region = data.aws_region.current.name
  setup_datamart         = local.application_data.accounts[local.environment].setup_redshift
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

### Iam Role for AWS Redshift
# Amazon Redshift supports only identity-based policies (IAM policies).

resource "aws_iam_role" "redshift-role" {
  count = local.setup_datamart ? 1 : 0
  name  = "dpr-redshift-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Principal = {
          "Service" = "redshift.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/aws-service-role/AmazonRedshiftServiceLinkedRolePolicy"
  ]

  tags = merge(
    local.tags,
    {
      name    = "redshift-service-role"
      project = "dpr"
    }
  )
}

# Amazon Redshift supports only identity-based policies (IAM policies).
data "aws_iam_policy_document" "redshift-additional-policy" {
  statement {
    actions = [
      "glue:*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:PutRetentionPolicy"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/redshift/*"
    ]
  }
  statement {
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "additional-policy" {
  name        = "dpr-redshift-policy"
  description = "Extra Policy for AWS Redshift"
  policy      = data.aws_iam_policy_document.redshift-additional-policy.json
}

resource "aws_iam_role_policy_attachment" "redshift" {
  role       = aws_iam_role.redshift-role[0].name
  policy_arn = aws_iam_policy.additional-policy.arn
}