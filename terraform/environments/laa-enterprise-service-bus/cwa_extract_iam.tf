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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cwa_extract_lambda_role_policy_attachment" {
  role       = aws_iam_role.cwa_extract_lambda_role.name
  policy_arn = aws_iam_policy.cwa_extract_lambda_policy.arn
}