## SSM Specific
resource "aws_iam_policy" "ec2_ssm_policy" {
  name        = "ssm_ec2_policy-${local.environment}"
  description = "allows SSM Connect logging"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:eu-west-2::log-group:/aws/ssm/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:*"
          ],
          "Resource" : [
            "arn:aws:ssm:eu-west-2:767123802783:*"
          ]
        },
        {
          "Action" : "s3:GetObject",
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:s3:::patch-baseline-snapshot-eu-west-2/*",
            "arn:aws:s3:::eu-west-2-birdwatcher-prod/*",
            "arn:aws:s3:::aws-windows-downloads-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-document-attachments-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-distributor-file-eu-west-2/*",
            "arn:aws:s3:::amazon-ssm-packages-eu-west-2/*",
            "arn:aws:s3:::amazon-ssm-eu-west-2/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_logging_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.ec2_ssm_policy.arn
}

## Oracle EC2 Policies
resource "aws_iam_role" "role_stsassume_oracle_base" {
  name                 = "role_stsassume_oracle_base"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  tags = merge(local.tags,
    { Name = lower(format("RoleSsm-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_policy_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach Secrets Manager Policy to Role
resource "aws_iam_role_policy_attachment" "secrets_manager_policy_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "iam_instace_profile_ccms_base" {
  name = "iam_instace_profile_ccms_base"
  role = aws_iam_role.role_stsassume_oracle_base.name
  path = "/"
  tags = merge(local.tags,
    { Name = lower(format("IamProfile-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
}

# Cloudwatch Logging
resource "aws_iam_policy" "cw_logging_policy" {
  name        = "cw_log_policy-${local.environment}"
  description = "allows EC2 CW logging"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:*:*:*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "cw_logging_policy" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.cw_logging_policy.arn
}

# RMAN policy
resource "aws_iam_policy" "rman_to_s3" {
  name        = "ec2_to_s3_policy-${local.environment}"
  description = "allows EC2 to write to S3"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetBucketLocation",
            "s3:ListAllMyBuckets"
          ],
          "Resource" : "arn:aws:s3:::*"
        },
        {
          "Effect" : "Allow",
          "Action" : ["s3:ListBucket"],
          "Resource" : [
            "arn:aws:s3:::ccms-ebs-*-dbbackup",
            "arn:aws:s3:::ccms-ebs-*-dbbackup/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject"
          ],
          "Resource" : [
            "arn:aws:s3:::ccms-ebs-*-dbbackup",
            "arn:aws:s3:::ccms-ebs-*-dbbackup/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "rman_to_s3_policy" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.rman_to_s3.arn
}

# Oracle Licensing policy
resource "aws_iam_policy" "oracle_licensing" {
  name        = "oracle_licensing_policy-${local.environment}"
  description = "Allows licensing metrics to be captured"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:PutObjectAcl",
            "s3:ListBucket",
            "s3:DeleteObject"
          ],
          "Resource" : [
            "arn:aws:s3:::license-manager-artifact-bucket/*",
            "arn:aws:s3:::license-manager-artifact-bucket"
          ],
          "Effect" : "Allow",
          "Sid" : "SSMS3BucketPolicy"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "oracle_licensing_policy" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.oracle_licensing.arn
}

# Access to LZ buckets.
resource "aws_iam_policy" "access_to_lz_buckets" {
  name        = "access_to_lz_buckets-${local.environment}"
  description = "Allows licensing metrics to be captured"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AccessToLZBuckets",
          "Effect" : "Allow",
          "Action" : [
            "s3:DeleteObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject"
          ],
          "Resource" : [
            "arn:aws:s3:::laa-ccms-inbound-*",
            "arn:aws:s3:::laa-ccms-outbound-*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "access_to_lz_buckets_policy" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.access_to_lz_buckets.arn
}

# Allow EC2 operations.
resource "aws_iam_policy" "ec2_operations_policy" {
  name        = "ec2_operations-${local.environment}"
  description = "Allows EC2 operations."

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "EC2Operations",
          "Effect" : "Allow",
          "Action" : [
            "ec2:Describe*",
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots",
            "ec2:DeleteSnapshot",
            "ec2:CreateTags",
            "ec2:DeleteTags"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ec2_operations_policy_att" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.ec2_operations_policy.arn
}

#Moved member infrastructure IAM resources from MP repo

#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "email" {
  #checkov:skip=CKV_AWS_273: "Skipping as tfsec check is also set to ignore"
  name = format("%s-%s-email_user", local.application_name, local.environment)
  tags = merge(local.tags,
    { Name = format("%s-%s-email_user", local.application_name, local.environment) }
  )
}

resource "aws_iam_access_key" "email" {
  user = aws_iam_user.email.name
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_user_policy" "email_policy" {
  name   = "AmazonSesSendingAccess"
  user   = aws_iam_user.email.name
  policy = data.aws_iam_policy_document.email.json
}

# Following AWS recommended policy
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "email" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_356: Policy follows AWS guidance
  statement {
    actions = [
      "ses:SendRawEmail"
    ]
    resources = ["*"]
  }
}

# S3 shared bucket
data "aws_iam_policy_document" "ccms_ebs_shared_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:CopyObject",
      "s3:DeleteObject",
      "s3:DeleteObjects",
      "s3:GetObject",
      "s3:ListObjects",
      "s3:ListObjectsV2",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.ccms_ebs_shared.arn,
      "${aws_s3_bucket.ccms_ebs_shared.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ccms_ebs_shared_s3" {
  description = "Policy to allow operations in ${aws_s3_bucket.ccms_ebs_shared.id}"
  name        = "ccms_ebs_shared_s3-${local.environment}"
  policy      = data.aws_iam_policy_document.ccms_ebs_shared_s3.json
}

resource "aws_iam_role_policy_attachment" "ccms_ebs_shared_s3" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.ccms_ebs_shared_s3.arn
}

# Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          }
        }
      ]
    }
  )
  tags = merge(local.tags,
    { Name = lower(format("Lambda Execution Role")) }
  )
}

# Attach S3 Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "s3_policy_lambda" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach ENI Management Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "eni_management_policy_lambda" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

# Attach VPC Access Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "vpc_access_policy_lambda" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach Secrets Manager Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "secrets_manager_policy_lambda" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# Hub-20 S3 Permissions Policy (Dev, Test, Production)
resource "aws_iam_policy" "hub_20_s3_permissions" {
  count       = contains(["development", "test", "production"], local.environment) ? 1 : 0
  name        = "hub-20-s3-permissions-${local.environment}"
  description = "Allows EC2 instances with role_stsassume_oracle_base to access Hub-20 ${local.environment} bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::hub20-${local.environment}-cwa-extract-data"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::hub20-${local.environment}-cwa-extract-data/*"
        ]
      }
    ]
  })

  tags = merge(local.tags,
    { Name = "hub-20-s3-permissions-${local.environment}" }
  )
}

# Attach Hub-20 S3 policy to EC2 role (Dev, Test, Production)
resource "aws_iam_role_policy_attachment" "hub_20_s3_permissions_attach" {
  count      = contains(["development", "test", "production"], local.environment) ? 1 : 0
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = one(aws_iam_policy.hub_20_s3_permissions[*].arn)
}

# Create policy to fetch secrets from secrets manager
resource "aws_iam_policy" "ccms_ebs_ftp_get_secrets_value" {
  description = "Policy to allow getting the secrets from aws secrets manager"
  count       = contains(["development", "test", "preproduction", "production"], local.environment) ? 1 : 0
  name        = "ccms_ebs_tp_get_secrets_value-${local.environment}"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowEC2InstanceToReadSecrets",
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource" : "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:ftp-s3-${local.environment}-aws-key-*",
      }
    ]
  })
}

# Attach get_secrets_value policy to EC2 role (Dev, test only)
resource "aws_iam_role_policy_attachment" "ccms_ebs_ftp_get_secrets_value_attach" {
  count      = contains(["development", "test", "preproduction", "production"], local.environment) ? 1 : 0
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = one(aws_iam_policy.ccms_ebs_ftp_get_secrets_value[*].arn)
}