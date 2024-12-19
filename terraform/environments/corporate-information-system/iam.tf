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
        Action   = "s3:*"
        Effect   = "Allow"
        "Resource" : [
          "arn:aws:s3:::laa-software-library",
          "arn:aws:s3:::laa-software-library/*"
        ],
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
          "arn:aws:s3:::laa-cis-inbound-production",
          "arn:aws:s3:::laa-cis-inbound-production/*",
          "arn:aws:s3:::laa-cis-outbound-production",
          "arn:aws:s3:::laa-cis-outbound-production/*",
          "arn:aws:s3:::laa-ccms-outbound-production",
          "arn:aws:s3:::laa-ccms-outbound-production/*",
          "arn:aws:s3:::laa-ccms-inbound-production",
          "arn:aws:s3:::laa-ccms-inbound-production/*"
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