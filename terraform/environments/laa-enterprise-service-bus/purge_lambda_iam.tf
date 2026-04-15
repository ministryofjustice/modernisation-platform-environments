resource "aws_iam_role" "purge_lambda_role" {
  name = "${local.application_name_short}-purge-lambda-role"

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
      Name = "${local.application_name_short}-${local.environment}-purge-lambda-role"
    }
  )
}

resource "aws_iam_policy" "purge_lambda_policy" {
  name = "${local.application_name_short}-purge-lambda-policy"

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
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          aws_s3_bucket.data.arn,
          "${aws_s3_bucket.data.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource = [
          aws_ssm_parameter.ccr_provider_load_timestamp.arn,
          aws_ssm_parameter.cclf_provider_load_timestamp.arn,
          aws_ssm_parameter.ccms_provider_load_timestamp.arn,
          aws_ssm_parameter.maat_provider_load_timestamp.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::${local.application_name_short}-${local.environment}-lambda-files/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "purge_lambda_role_policy_attachment" {
  role       = aws_iam_role.purge_lambda_role.name
  policy_arn = aws_iam_policy.purge_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "purge_lambda_vpc_access" {
  role       = aws_iam_role.purge_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
