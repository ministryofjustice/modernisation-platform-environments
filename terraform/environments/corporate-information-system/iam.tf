######################################
# CIS DB IAM Role & Policy
######################################

resource "aws_iam_role" "cis_ec2_role" {
  name = "${local.application_name_short}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cis_ec2_role_policy_attachment" {
  role       = aws_iam_role.cis_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "cis_ec2_policy" {
  name = "${local.application_name_short}-ec2-policy"
  role = aws_iam_role.cis_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::laa-software-library",
          "arn:aws:s3:::laa-software-library/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:aws:iam::${local.application_data.accounts[local.environment].acc_id_s3_software_library}:role/${local.application_data.accounts[local.environment].role_id_s3_software_library}"
      }
    ]
  })
}


######################################
# CIS S3FS IAM Role & Policy
######################################

resource "aws_iam_role" "cis_s3fs_role" {
  name = "${local.application_name_short}-s3fs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cis_s3fs_role_policy_attachment" {
  role       = aws_iam_role.cis_s3fs_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "cis_s3fs_policy" {
  name = "${local.application_name_short}-s3fs-policy"
  role = aws_iam_role.cis_s3fs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "arn:aws:s3:::laa-software-bucket2",
          "arn:aws:s3:::laa-software-bucket2/*",
          "arn:aws:s3:::laa-software-library",
          "arn:aws:s3:::laa-software-library/*",
          "arn:aws:s3:::laa-cis-inbound-${local.application_data.accounts[local.environment].s3_bucket_env}",
          "arn:aws:s3:::laa-cis-inbound-${local.application_data.accounts[local.environment].s3_bucket_env}/*",
          "arn:aws:s3:::laa-cis-outbound-${local.application_data.accounts[local.environment].s3_bucket_env}",
          "arn:aws:s3:::laa-cis-outbound-${local.application_data.accounts[local.environment].s3_bucket_env}/*",
          "arn:aws:s3:::laa-ccms-outbound-${local.application_data.accounts[local.environment].s3_bucket_env}",
          "arn:aws:s3:::laa-ccms-outbound-${local.application_data.accounts[local.environment].s3_bucket_env}/*",
          "arn:aws:s3:::laa-ccms-inbound-${local.application_data.accounts[local.environment].s3_bucket_env}",
          "arn:aws:s3:::laa-ccms-inbound-${local.application_data.accounts[local.environment].s3_bucket_env}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy",
          "logs:PutLogEvents",
          "ec2:DescribeInstances"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}