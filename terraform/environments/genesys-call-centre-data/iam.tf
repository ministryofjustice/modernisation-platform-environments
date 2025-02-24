locals {
  # Workspace name = genesys-call-centre-data-development
  # Create a local variable that stores the last part of the workspace name
  bt_roles = {
    development = [
      "arn:aws:iam::572734708359:role/a3s-di-core-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-outbound-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-survey-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-sta-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-wfm-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-ivr-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-qm-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-eb-int-moj-ingestion-role-eu-west-2-demo",
    ]
    production = [
      "arn:aws:iam::572734708359:role/a3s-di-core-int-moj-ingestion-role-eu-west-2-demo",
    ]
  }
}

# This is the role that BT will assume to upload files into the S3 bucket
resource "aws_iam_role" "cross_account_assume_role" {
  name = "bt-genesys-s3-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = local.bt_roles[local.environment]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create a policy to allow the role to write and list to/on a specific S3 bucket
resource "aws_iam_policy" "cross_account_assume_role_policy" {
  name = "bt-genesys-s3-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_bucket_staging.bucket.arn,
          "${module.s3_bucket_staging.bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cross_account_assume_role_policy_attachment" {
  role       = aws_iam_role.cross_account_assume_role.name
  policy_arn = aws_iam_policy.cross_account_assume_role_policy.arn
}
