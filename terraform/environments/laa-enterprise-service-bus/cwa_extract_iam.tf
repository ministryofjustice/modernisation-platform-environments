resource "aws_iam_role" "cwa_extract_lambda_role" {
  name = "${local.application_name_short}-cwa-extract-lambda-role"

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
      Name = "${local.application_name_short}-cwa-extract-lambda-role"
    }
  )
}

resource "aws_iam_policy" "cwa_extract_lambda_policy" {
  name = "${local.application_name_short}-cwa-extract-lambda-policy"

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
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.cwa_procedures_config.arn,
          aws_secretsmanager_secret.cwa_db_secret.arn,
          aws_secretsmanager_secret.cwa_table_name_secret.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:DescribeAccessPoints"
      ],
        Resource = [
          "arn:aws:elasticfilesystem:eu-west-2:940482439836:file-system/fs-08be7f58b2bd6aaff",
          "arn:aws:elasticfilesystem:eu-west-2:940482439836:access-point/fsap-0b3ad02899e9b5922"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "elasticfilesystem:DescribeMountTargets"
      ],
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
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

resource "aws_iam_role_policy_attachment" "cwa_extract_lambda_role_policy_attachment" {
  role       = aws_iam_role.cwa_extract_lambda_role.name
  policy_arn = aws_iam_policy.cwa_extract_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "cwa_extract_lambda_vpc_access" {
  role       = aws_iam_role.cwa_extract_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
