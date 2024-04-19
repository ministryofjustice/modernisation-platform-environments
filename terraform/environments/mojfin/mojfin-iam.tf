resource "aws_iam_role" "mojfin_rds_oracle" {
  name        = "mojfin_rds_oracle-${local.environment}"
  description = "Role for Oracle RDS in ${local.environment}"

  assume_role_policy = data.aws_iam_policy_document.mojfin_rds_oracle_assume.json
}

data "aws_iam_policy_document" "mojfin_rds_oracle_assume" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "rds.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "mojfin_rds_oracle_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.mojfin_rds_oracle.arn,
      "${aws_s3_bucket.mojfin_rds_oracle.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "mojfin_rds_oracle_s3" {
  name        = "mojfin_rds_oracle_s3-${local.environment}"
  description = "Policy for Oracle RDS in ${local.environment}"
  policy      = data.aws_iam_policy_document.mojfin_rds_oracle_s3.json
}

resource "aws_iam_role_policy_attachment" "mojfin_rds_oracle_s3" {
  role       = aws_iam_role.mojfin_rds_oracle.name
  policy_arn = aws_iam_policy.mojfin_rds_oracle_s3.arn
}

resource "aws_db_instance_role_association" "mojfin_rds_oracle" {
  db_instance_identifier = aws_db_instance.appdb1.identifier
  feature_name           = "S3_INTEGRATION"
  role_arn               = aws_iam_role.mojfin_rds_oracle.arn
}
