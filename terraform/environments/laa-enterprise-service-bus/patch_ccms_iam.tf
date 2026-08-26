#####################################################################################
######################### IAM Role and policy for CCMS Lambda #######################
#####################################################################################
resource "aws_iam_role" "patch_ccms_provider_load_role" {
  count = local.environment == "test" ? 1 : 0
  name  = "${local.application_name_short}-patch-ccms-provider-load-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-ccms-provider-load-role"
    }
  )
}

resource "aws_iam_policy" "patch_ccms_provider_load_policy" {
  count = local.environment == "test" ? 1 : 0
  name  = "${local.application_name_short}-patch-ccms-provider-load-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ],
        Resource = [
          "${aws_s3_bucket.patch_data[0].arn}",
          "${aws_s3_bucket.patch_data[0].arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::${local.application_name_short}-${local.environment}-lambda-files/*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          aws_secretsmanager_secret.patch_ccms_db_mp_credentials[0].arn,
          aws_secretsmanager_secret.patch_ccms_procedures_config[0].arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.patch_ccms_provider_q[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.patch_ccms_provider_dlq[0].arn
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter"
        ],
        Resource = aws_ssm_parameter.ccms_provider_load_timestamp.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "patch_ccms_provider_load_lambda_role_policy_attachment" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_ccms_provider_load_role[0].name
  policy_arn = aws_iam_policy.patch_ccms_provider_load_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "patch_ccms_provider_load_lambda_vpc_access" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_ccms_provider_load_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

#####################################################################################
## IAM Role for CCMS Instance for mounting extract data S3 bucket ###################
#####################################################################################

resource "aws_iam_role" "patch_ccms_cross_account_s3_read" {
  count = local.environment == "test" ? 1 : 0
  name  = "${local.application_name_short}-${local.environment}-patch-ccms-cross-account-s3-read"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::730335523459:role/role_stsassume_oracle_base"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-ccms-cross-account-s3-read"
    }
  )
}

resource "aws_iam_policy" "patch_ccms_cross_account_s3_read_policy" {
  count = local.environment == "test" ? 1 : 0
  name  = "${local.application_name_short}-${local.environment}-patch-ccms-cross-account-s3-read-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ],
        Resource = [
          "${aws_s3_bucket.patch_data[0].arn}",
          "${aws_s3_bucket.patch_data[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "patch_ccms_cross_account_s3_read_attach" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_ccms_cross_account_s3_read[0].name
  policy_arn = aws_iam_policy.patch_ccms_cross_account_s3_read_policy[0].arn
}
