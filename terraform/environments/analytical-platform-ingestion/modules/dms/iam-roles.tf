data "aws_caller_identity" "current" {}

# IAM Role for DMS VPC Access
resource "aws_iam_role" "dms" {
  name = "${var.db}-dms-${var.environment}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "dms.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    { Name = "${var.db}-dms-${var.environment}" },
    var.tags
  )
}

resource "aws_iam_role_policy" "dms" {
  name = "${var.db}-dms-${var.environment}"
  role = aws_iam_role.dms.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.landing.bucket}",
        "Sid" : "AllowListBucket"
      },
      {
        "Action" : [
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.landing.bucket}/*",
        "Sid" : "AllowDeleteAndPutObject"
      },
      {
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:secret:managed_pipelines/${var.environment}/slack_notifications*",
        "Sid" : "AllowGetSecretValue"
      }
    ]
  })
}

resource "aws_iam_role" "dms_source" {
  name = "${var.db}-dms-source-${var.environment}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "dms.${data.aws_region.current.name}.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    { Name = "${var.db}-dms-${var.environment}" },
    var.tags
  )
}

resource "aws_iam_role_policy" "dms_source" {
  name = "${var.db}-dms-source-${var.environment}"
  role = aws_iam_role.dms_source.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Effect" : "Allow",
        "Resource" : var.dms_source.secrets_manager_arn,
        "Sid" : "AllowGetSecretValue"
      }
    ]
  })
}
