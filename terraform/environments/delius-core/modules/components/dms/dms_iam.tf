data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-cloudwatch-logs-role"
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-vpc-role"
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}

resource "aws_iam_role" "dms_client_s3_list_role" {
 count = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  name = "dms-client-s3-list-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for principal in var.dms_config.client_account_arns:
      {
        Effect = "Allow",
        Principal = {
          AWS = principal
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "dms_client_s3_put_role" {
 count = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  name = "dms-client-s3-put-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for principal in var.dms_config.client_account_arns:
      {
        Effect = "Allow",
        Principal = {
          AWS = principal
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


data "aws_iam_policy_document" "dms_client_s3_list_policy_data" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketAcl"
    ]

    resources = [
      "arn:aws:s3:::*",
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.env_name}-dms-destination-bucket*"]
    }
  }
}

resource "aws_iam_policy" "dms_client_s3_list_policy" {
  count       = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  name        = "dms-client-s3-list-policy"
  description = "Policy to allow audit clients listing S3 buckets with DMS destination prefix"
  policy      = data.aws_iam_policy_document.dms_client_s3_list_policy_data.json
}

resource "aws_iam_role_policy_attachment" "dms_client_s3_list_policy_attachment" {
  count      = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  role       = aws_iam_role.dms_client_s3_list_role[0].name
  policy_arn = aws_iam_policy.dms_client_s3_list_policy[0].arn
}

data "aws_iam_policy_document" "dms_client_s3_put_policy_data"  {
 statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "arn:aws:s3:::${local.dms_s3_local_bucket_prefix}*",
      "arn:aws:s3:::${local.dms_s3_local_bucket_prefix}*/*"
    ]
  }
}

resource "aws_iam_policy" "dms_client_s3_put_policy" {
  count       = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  name        = "dms-client-s3-put-policy"
  description = "Policy to allow audit clients putting data to S3 buckets with DMS destination prefix"
  policy      = data.aws_iam_policy_document.dms_client_s3_put_policy_data.json
}

resource "aws_iam_role_policy_attachment" "dms_client_s3_put_policy_attachment" {
  count      = length(var.dms_config.client_account_arns) > 0 ? 1 : 0
  role       = aws_iam_role.dms_client_s3_put_role[0].name
  policy_arn = aws_iam_policy.dms_client_s3_put_policy[0].arn
}


resource "aws_iam_policy" "dms_s3_audit_target_policy" {
  count       = local.dms_s3_repository_bucket.prefix == null ? 0 : 1
  name        = "dms-s3-target-policy"
  description = "Policy to allow DMS to write Audit data to the repository S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.dms_s3_repository_bucket.prefix}*",
          "arn:aws:s3:::${local.dms_s3_repository_bucket.prefix}*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_s3_audit_target_policy_attachment" {
  count      = local.dms_s3_repository_bucket.prefix == null ? 0 : 1
  role       = aws_iam_role.dms-vpc-role.name
  policy_arn = aws_iam_policy.dms_s3_audit_target_policy[0].arn
}

# Policy to allow terraform to list the buckets in the repository account when it
# is being run in the client account by assuming the List Buckets role in the repository account
resource "aws_iam_policy" "terraform_assume_dms_client_s3_list_role_policy" {
  count       = local.dms_s3_repository_bucket.prefix == null ? 0 : 1
  name        = "terraform-list-s3-buckets"
  description = "Policy to allow Terraform access to role for listing s3 buckets in an audit repository account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:aws:iam::${local.dms_s3_repository_bucket.account_id}:role/dms-client-s3-list-role"
      }
    ]
  })
}

# Attach this policy to the github-actions role since this is the one used to run the Terraform
resource "aws_iam_role_policy_attachment" "terraform_assume_dms_client_s3_list_role_policy_attachment" {
  count      = local.dms_s3_repository_bucket.prefix == null ? 0 : 1
  role       = "github-actions"
  policy_arn = aws_iam_policy.terraform_assume_dms_client_s3_list_role_policy[0].arn
}
