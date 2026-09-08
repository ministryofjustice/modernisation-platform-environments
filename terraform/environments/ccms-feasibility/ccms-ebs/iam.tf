# EBS DB IAM role

resource "aws_iam_role" "ebsdb" {
  name                 = "${local.component_name}-${local.env_label}-ebsdb-role"
  path                 = "/"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {}
    }]
  })

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsdb-role"
  })
}

resource "aws_iam_instance_profile" "ebsdb" {
  name = "${local.component_name}-${local.env_label}-ebsdb-role"
  role = aws_iam_role.ebsdb.name
  path = "/"

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsdb-role"
  })
}

resource "aws_iam_role_policy_attachment" "ebsdb_ssm" {
  role       = aws_iam_role.ebsdb.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ebsdb_cw_logging" {
  name        = "${local.component_name}-${local.env_label}-ebsdb-cw-logging"
  description = "Allow EBS DB instance to write CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Describe APIs cannot be scoped to specific log groups
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/${local.component_name}/*",
          "arn:aws:logs:*:*:log-group:/${local.component_name}/*:log-stream:*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebsdb_cw_logging" {
  role       = aws_iam_role.ebsdb.name
  policy_arn = aws_iam_policy.ebsdb_cw_logging.arn
}

resource "aws_iam_role_policy_attachment" "ebsdb_rman_to_s3" {
  role       = aws_iam_role.ebsdb.name
  policy_arn = aws_iam_policy.rman_to_s3.arn
}

resource "aws_iam_role_policy_attachment" "ebsdb_ec2_operations" {
  role       = aws_iam_role.ebsdb.name
  policy_arn = aws_iam_policy.ec2_operations.arn
}

# EBS Apps IAM role (used by both ebsapps instances)

resource "aws_iam_role" "ebsapps" {
  name                 = "${local.component_name}-${local.env_label}-ebsapps-role"
  path                 = "/"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {}
    }]
  })

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsapps-role"
  })
}

resource "aws_iam_instance_profile" "ebsapps" {
  name = "${local.component_name}-${local.env_label}-ebsapps-role"
  role = aws_iam_role.ebsapps.name
  path = "/"

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsapps-role"
  })
}

resource "aws_iam_role_policy_attachment" "ebsapps_ssm" {
  role       = aws_iam_role.ebsapps.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ebsapps_cw_logging" {
  name        = "${local.component_name}-${local.env_label}-ebsapps-cw-logging"
  description = "Allow EBS apps instances to write CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Describe APIs cannot be scoped to specific log groups
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/${local.component_name}/*",
          "arn:aws:logs:*:*:log-group:/${local.component_name}/*:log-stream:*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebsapps_cw_logging" {
  role       = aws_iam_role.ebsapps.name
  policy_arn = aws_iam_policy.ebsapps_cw_logging.arn
}

# Shared secret access for EBS DB and Apps instances
# Covers secrets manually created (or created in future) under the ccms-ebs- naming prefix

resource "aws_iam_policy" "ebs_shared_secrets" {
  name        = "${local.component_name}-${local.env_label}-ebs-shared-secrets"
  description = "Allow EBS DB and Apps instances to read secrets prefixed ccms-ebs-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ccmsebsfeasibilitysecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:ccms-ebs-*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebsdb_shared_secrets" {
  role       = aws_iam_role.ebsdb.name
  policy_arn = aws_iam_policy.ebs_shared_secrets.arn
}

resource "aws_iam_role_policy_attachment" "ebsapps_shared_secrets" {
  role       = aws_iam_role.ebsapps.name
  policy_arn = aws_iam_policy.ebs_shared_secrets.arn
}

resource "aws_iam_policy" "rman_to_s3" {
  name        = "${local.component_name}-${local.env_label}-ebsdb-rman-s3"
  description = "Allow the EBS DB instance to write RMAN backups to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # ListAllMyBuckets cannot be scoped to a specific bucket
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets"]
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Resource = module.s3_dbbackup.bucket.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = "${module.s3_dbbackup.bucket.arn}/*"
      },
    ]
  })
}

# FTP IAM role

resource "aws_iam_role" "ftp" {
  name                 = "${local.component_name}-${local.env_label}-ftp-role"
  path                 = "/"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {}
    }]
  })

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ftp-role"
  })
}

resource "aws_iam_instance_profile" "ftp" {
  name = "${local.component_name}-${local.env_label}-ftp-role"
  role = aws_iam_role.ftp.name
  path = "/"

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ftp-role"
  })
}

resource "aws_iam_role_policy_attachment" "ftp_ssm" {
  role       = aws_iam_role.ftp.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ftp_cw_logging" {
  name        = "${local.component_name}-${local.env_label}-ftp-cw-logging"
  description = "Allow FTP instance to write CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Describe APIs cannot be scoped to specific log groups
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/${local.component_name}/*",
          "arn:aws:logs:*:*:log-group:/${local.component_name}/*:log-stream:*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ftp_cw_logging" {
  role       = aws_iam_role.ftp.name
  policy_arn = aws_iam_policy.ftp_cw_logging.arn
}

resource "aws_iam_policy" "ftp_s3_buckets" {
  name        = "${local.component_name}-${local.env_label}-ftp-s3-buckets"
  description = "Allow the FTP instance to mount the inbound/outbound S3 buckets via s3fs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
        ]
        Resource = [
          module.s3_inbound.bucket.arn,
          module.s3_outbound.bucket.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "${module.s3_inbound.bucket.arn}/*",
          "${module.s3_outbound.bucket.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ftp_s3_buckets" {
  role       = aws_iam_role.ftp.name
  policy_arn = aws_iam_policy.ftp_s3_buckets.arn
}

resource "aws_iam_policy" "ftp_test_user_secret" {
  name        = "${local.component_name}-${local.env_label}-ftp-test-user-secret"
  description = "Allow the FTP instance to read its own SSH test user credentials at boot"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.ftp_test_user.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ftp_test_user_secret" {
  role       = aws_iam_role.ftp.name
  policy_arn = aws_iam_policy.ftp_test_user_secret.arn
}

resource "aws_iam_policy" "ec2_operations" {
  name        = "${local.component_name}-${local.env_label}-ebsdb-ec2-operations"
  description = "Allow the EBS DB instance to create and manage EBS snapshots"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Describe APIs have no resource-level restriction in AWS
        Effect   = "Allow"
        Action   = ["ec2:Describe*"]
        Resource = "*"
      },
      {
        # Restrict snapshot creation to volumes tagged to this component
        Effect   = "Allow"
        Action   = ["ec2:CreateSnapshot", "ec2:CreateSnapshots"]
        Resource = "arn:aws:ec2:eu-west-2:*:volume/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/instance-role" = "ebsdb"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:CreateSnapshot", "ec2:CreateSnapshots"]
        Resource = "arn:aws:ec2:eu-west-2:*:snapshot/*"
      },
      {
        # Restrict snapshot deletion to snapshots tagged to this component
        Effect   = "Allow"
        Action   = ["ec2:DeleteSnapshot"]
        Resource = "arn:aws:ec2:eu-west-2:*:snapshot/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/instance-role" = "ebsdb"
          }
        }
      },
      {
        # Allow tagging only at snapshot creation time, not arbitrary resources
        Effect   = "Allow"
        Action   = ["ec2:CreateTags"]
        Resource = "arn:aws:ec2:eu-west-2:*:snapshot/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = ["CreateSnapshot", "CreateSnapshots"]
          }
        }
      },
    ]
  })
}
