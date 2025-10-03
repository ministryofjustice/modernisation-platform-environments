resource "aws_iam_role" "patch_cwa_extract_lambda_role" {
  count = local.environment == "test" ? 1 : 0
  name  = "${local.application_name_short}-patch-cwa-extract-lambda-role"

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
      Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-lambda-role"
    }
  )
}

resource "aws_iam_policy" "patch_cwa_extract_lambda_policy" {
  count = local.environment == "test" ? 1 : 0
  name  = "${local.application_name_short}-patch-cwa-extract-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.data.arn}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.lambda_layer_dependencies.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.cwa_procedures_config.arn,
          aws_secretsmanager_secret.cwa_db_secret.arn,
          aws_secretsmanager_secret.cwa_table_name_secret.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ],
        Resource = [
          aws_sns_topic.priority_p1.arn,
          aws_sns_topic.provider_banks.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "patch_cwa_extract_lambda_role_policy_attachment" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_cwa_extract_lambda_role.name
  policy_arn = aws_iam_policy.patch_cwa_extract_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "patch_cwa_extract_lambda_vpc_access" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_cwa_extract_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
