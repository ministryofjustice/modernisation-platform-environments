#####################################################################################
######################### IAM Role and policy for CCR Lambda #######################
#####################################################################################
resource "aws_iam_role" "ccr_provider_load_role" {
  name = "${local.application_name_short}-ccr-provider-load-role"

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
      Name = "${local.application_name_short}-${local.environment}-ccr-provider-load-role"
    }
  )
}

resource "aws_iam_policy" "ccr_provider_load_policy" {
  name = "${local.application_name_short}-ccr-provider-load-policy"

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
          "${aws_s3_bucket.data.arn}",
          "${aws_s3_bucket.data.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::${local.application_name_short}-${local.environment}-lambda-files/layers_files/*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          aws_secretsmanager_secret.ccr_db_mp_credentials.arn,
          aws_secretsmanager_secret.ccr_procedures_config.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.ccr_provider_q.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.ccr_provider_dlq.arn
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter"
        ],
        Resource = aws_ssm_parameter.ccr_provider_load_timestamp.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.hub2_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ccr_provider_load_lambda_role_policy_attachment" {
  role       = aws_iam_role.ccr_provider_load_role.name
  policy_arn = aws_iam_policy.ccr_provider_load_policy.arn
}

resource "aws_iam_role_policy_attachment" "ccr_provider_load_lambda_vpc_access" {
  role       = aws_iam_role.ccr_provider_load_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
