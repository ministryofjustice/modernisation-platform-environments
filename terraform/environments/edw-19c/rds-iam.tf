##################################################################################################################
### RDS IAM Role and Policy for S3 Access (for Data Pump import from S3)
##################################################################################################################

resource "aws_iam_policy" "rds_s3_access_policy" {
  count = local.environment == "preproduction" ? 1 : 0

  name        = "${local.application_name}-rds-s3-access-policy"
  description = "Policy to allow RDS access to S3 buckets for Data Pump imports"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.replica[0].arn,
          "${aws_s3_bucket.replica[0].arn}/*"
        ]
      }
    ]
  })

}

resource "aws_iam_role" "rds_s3_access_role" {
  count = local.environment == "preproduction" ? 1 : 0

  name = "${local.application_name}-rds-s3-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_s3_access_attachment" {
  count = local.environment == "preproduction" ? 1 : 0

  role       = aws_iam_role.rds_s3_access_role[0].name
  policy_arn = aws_iam_policy.rds_s3_access_policy[0].arn
}
