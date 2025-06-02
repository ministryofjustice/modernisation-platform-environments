data "aws_caller_identity" "current" {}

# IAM Role for DMS VPC Access
resource "aws_iam_role" "dms_vpc" {
  count = var.create_ancillary_static_roles ? 1 : 0
  # This has to be a specific name for some reason see https://repost.aws/questions/QU61eADUU7SnO-t7MmhxgfPA/dms-service-roles
  name = "dms-vpc-role"
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
    { Name = "dms-vpc-role" },
    var.tags
  )
}

resource "aws_iam_role" "dms" {
  name = "${var.db}-dms-role-${var.environment}"

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
    { Name = "${var.db}-dms-role-${var.environment}" },
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

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  count      = var.create_ancillary_static_roles ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms_vpc[0].name

  # It takes some time for these attachments to work, and creating the aws_dms_replication_subnet_group fails if this attachment hasn't completed.
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

# IAM Role for DMS Cloudwatch Access
resource "aws_iam_role" "dms_cloudwatch" {
  count = var.create_ancillary_static_roles ? 1 : 0
  # This has to be a specific name for some reason
  name = "dms-cloudwatch-logs-role"
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
    { Name = "dms-cloudwatch-logs-role" },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  count      = var.create_ancillary_static_roles ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms_cloudwatch[0].name
}

# IAM Role for DMS Premigration Assessmeent
resource "aws_iam_role" "dms_premigration" {
  count = var.create_premigration_assessement_resources ? 1 : 0
  name  = "dms-premigration-assessment-role-${var.db}"
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
    { Name = "dms-premigration-assessment-role" },
    var.tags
  )
}


resource "aws_iam_role_policy" "dms_premigration" {
  count = var.create_premigration_assessement_resources ? 1 : 0
  name  = "${var.db}-dms-premigration-${var.environment}"
  role  = aws_iam_role.dms_premigration[0].id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObjectTagging"
        ],
        "Resource" : [
          "${aws_s3_bucket.premigration_assessment[0].arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          aws_s3_bucket.premigration_assessment[0].arn
        ]
      }
    ]
  })
}
